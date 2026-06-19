#!/bin/bash
set -euo pipefail

DOTFILES_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS (sets SYSTEM_OS) and load shared helpers (winpath) from the same
# file bashrc uses, so the installer and the shell never disagree. Source the
# repo copy: the ~/.os_env symlink may not exist yet on a first run.
. "$DOTFILES_PATH/os_env"

# Use Windows-form (C:/...) paths for both DOTFILES_PATH and HOME so each
# symlink's link and target are paths native Windows tools resolve, not the
# MSYS "/c/..." form (which non-MSYS tools like nvim.exe can't follow). pwd
# yields "/c/..." while bashrc normalizes HOME to "C:/...", so without this the
# two halves of every symlink would disagree. winpath is a no-op off Windows.
DOTFILES_PATH="$(winpath "$DOTFILES_PATH")"
export HOME="$(winpath "$HOME")"

BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Backup existing settings and symlink new settings
setup_symlink() {
    local src_file="$1"
    local dest_file="$2"

    # error if file doesn't exist in dotfiles repo
    if [ ! -e "$src_file" ]; then
        echo "Error: $src_file does not exist"
        return 1
    fi

    # Check if dotfiles already exist/symlinked and backup accordingly
    if [ -e "$dest_file" ] || [ -L "$dest_file" ]; then
        if [ -L "$dest_file" ] && [ "$(readlink "$dest_file")" = "$src_file" ]; then
            echo "Symlink already correct for $dest_file"
            return 0
        fi

        echo "Backing up existing $dest_file to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        mv "$dest_file" "$BACKUP_DIR/"
    fi

    # Create symlink
    mkdir -p "$(dirname "$dest_file")"
    echo "Creating symlink $dest_file -> $src_file"
    ln -s "$src_file" "$dest_file"
}

# Mirror Neovim's own config-dir resolution: $XDG_CONFIG_HOME/nvim if set
# (honored on every platform), else the OS default — ~/AppData/Local/nvim on
# Windows (%LOCALAPPDATA%), ~/.config/nvim elsewhere. Branches on SYSTEM_OS
# from os_env.
nvim_config_dir() {
    if [ -n "${XDG_CONFIG_HOME:-}" ]; then
        printf '%s/nvim' "$(printf '%s' "$XDG_CONFIG_HOME" | tr '\134' '/')"
    elif [ "$SYSTEM_OS" = "Windows" ]; then
        local base="${LOCALAPPDATA:-$HOME/AppData/Local}"
        printf '%s/nvim' "$(printf '%s' "$base" | tr '\134' '/')"
    else
        printf '%s/nvim' "$HOME/.config"
    fi
}

# WezTerm reads its config from $XDG_CONFIG_HOME/wezterm if set, else
# ~/.config/wezterm on every platform -- unlike Neovim it does NOT use AppData
# on Windows. Same XDG handling as nvim_config_dir, minus the Windows branch.
wezterm_config_dir() {
    if [ -n "${XDG_CONFIG_HOME:-}" ]; then
        printf '%s/wezterm' "$(printf '%s' "$XDG_CONFIG_HOME" | tr '\134' '/')"
    else
        printf '%s/wezterm' "$HOME/.config"
    fi
}

setup_dotfiles() {
    echo "Setting up dotfiles"

    setup_symlink "$DOTFILES_PATH/os_env" "$HOME/.os_env"
    setup_symlink "$DOTFILES_PATH/bashrc" "$HOME/.bashrc"
    setup_symlink "$DOTFILES_PATH/bashrc_linux" "$HOME/.bashrc_linux"
    setup_symlink "$DOTFILES_PATH/bashrc_macos" "$HOME/.bashrc_macos"
    setup_symlink "$DOTFILES_PATH/bashrc_windows" "$HOME/.bashrc_windows"
    setup_symlink "$DOTFILES_PATH/bash_profile" "$HOME/.bash_profile"
    setup_symlink "$DOTFILES_PATH/nvim" "$(nvim_config_dir)"
    setup_symlink "$DOTFILES_PATH/wezterm" "$(wezterm_config_dir)"
    setup_symlink "$DOTFILES_PATH/bash_aliases" "$HOME/.bash_aliases"
    setup_symlink "$DOTFILES_PATH/gitconfig" "$HOME/.gitconfig"

    echo "Successfully set up dotfiles"
}

setup_claude() {
    echo "Setting up Claude config"

    # Symlink each tracked config entry from claude/ into ~/.claude/.
    # Only config files belong in claude/; ~/.claude runtime state
    # (credentials, history, sessions, jobs) is left untouched.
    for src in "$DOTFILES_PATH/claude/"*; do
        [ -e "$src" ] || continue
        setup_symlink "$src" "$HOME/.claude/$(basename "$src")"
    done

    echo "Successfully set up Claude config"
}

install_starship() {
    # If starship exists
    if command -v starship >/dev/null 2>&1; then
        echo "Starship already installed"
    else
        echo "Installing starship"
        mkdir -p ~/.local/bin
        curl -sS https://starship.rs/install.sh | sh -s -- -b ~/.local/bin
        echo "Starship installed"
    fi
}

install_uv() {
    # If uv exists
    if command -v uv >/dev/null 2>&1; then
        echo "uv already installed"
    else
        echo "Installing uv"
        curl -LsSf https://astral.sh/uv/install.sh | sh
        echo "uv installed"
    fi
}

# Install external tools. This is the default (Unix) implementation using the
# upstream curl|sh installers; a per-OS init file (see init_<os>.sh, sourced
# below) may override it -- e.g. Windows uses a package manager instead.
install_tools() {
    install_starship
    install_uv
}

setup_pyenv() {
    # uv puts the activate script under Scripts/ on Windows, bin/ on Unix.
    local activate="$HOME/py313/bin/activate"
    [ "$SYSTEM_OS" = "Windows" ] && activate="$HOME/py313/Scripts/activate"

    if [ -e "$activate" ]; then
        echo "Virtual env already set up"
    else
        echo "Setting up pyenv"
        uv venv "$HOME/py313" --seed --python 3.13
        echo "Pyenv setup"
    fi
    echo "run pyenv to activate"
}

# Generate bash completions into the user completions dir, where bash-completion
# lazy-loads each file on the first TAB for that command -- so there's no shell
# startup cost (unlike eval-ing them in bashrc, where uv alone is ~10k lines).
# Gate every file on the command it completes existing, so an uninstalled tool
# produces no file and the loader just falls back to default completion. This is
# the per-tool completion install the authors document (e.g. rustup). Files go
# stale on a tool upgrade; re-run init.sh to refresh them.
setup_completions() {
    echo "Generating bash completions"
    local dir="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
    mkdir -p "$dir"

    # gen_completion <completed-command> <generator...>: the file is named after
    # the command bash-completion looks up, but the generator can differ (cargo's
    # completion is emitted by rustup). Write to .tmp then mv so a failed
    # generation never leaves an empty file shadowing the real completion.
    gen_completion() {
        local cmd="$1"; shift
        command -v "$cmd" >/dev/null 2>&1 || return 0
        if "$@" > "$dir/$cmd.tmp" 2>/dev/null; then
            mv "$dir/$cmd.tmp" "$dir/$cmd"
        else
            rm -f "$dir/$cmd.tmp"
            echo "Warning: could not generate $cmd completion"
        fi
    }

    gen_completion uv     uv  generate-shell-completion bash
    gen_completion uvx    uvx --generate-shell-completion bash
    gen_completion pixi   pixi completion --shell bash
    gen_completion rustup rustup completions bash
    gen_completion cargo  rustup completions bash cargo

    echo "Completions written to $dir"
}

# Per-OS extra setup hook. Default no-op; a per-OS init file (init_<os>.sh,
# sourced below) may override it -- e.g. Linux installs a WezTerm desktop entry.
# Runs as a step below, after the core setup.
setup_os() {
    :
}

# Source per-OS overrides (e.g. install_tools, env like MSYS). Done after the
# default definitions above so an OS file can override them, but before the
# steps run below so its setup (e.g. MSYS for symlinks) takes effect. Sourced
# from the repo copy since the ~/.* symlinks may not exist yet on a first run.
os_init="$DOTFILES_PATH/init_$(printf '%s' "$SYSTEM_OS" | tr '[:upper:]' '[:lower:]').sh"
if [ -f "$os_init" ]; then
    . "$os_init"
fi

setup_dotfiles
setup_claude
setup_os
install_tools
setup_pyenv
setup_completions

# Don't `source ~/.bashrc` here: this script runs in its own non-interactive
# subshell (`bash init.sh`), so bashrc's interactive guard early-returns before
# loading bash_aliases, and anything it did set couldn't propagate to the parent
# shell that ran the script. The user must reload it themselves.
echo
echo "Done. Open a new shell or run:  source ~/.bashrc"



