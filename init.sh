#!/bin/bash
set -euo pipefail

DOTFILES_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS + load shared helpers from the same file bashrc uses, so the
# installer and shell agree. Source the repo copy: ~/.shellenv may not exist yet.
. "$DOTFILES_PATH/shellenv"

# Windows-form (C:/...) paths so each symlink's link and target are native paths
# nvim.exe etc. can follow (not MSYS /c/...). pwd gives /c/... and bashrc
# normalizes HOME to C:/..., so without this the two halves disagree. No-op off
# Windows.
DOTFILES_PATH="$(winpath "$DOTFILES_PATH")"
export HOME="$(winpath "$HOME")"

BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Back up any existing file, then symlink ours in its place.
setup_symlink() {
    local src_file="$1"
    local dest_file="$2"

    if [ ! -e "$src_file" ]; then
        echo "Error: $src_file does not exist"
        return 1
    fi

    if [ -e "$dest_file" ] || [ -L "$dest_file" ]; then
        # Already correct? Compare in winpath form: on Windows `ln -s` gets the
        # C:/ target but readlink reports /c/, so a raw compare never matches and
        # we'd recreate every run. No-op on Unix, where both sides agree.
        if [ -L "$dest_file" ] && \
           [ "$(winpath "$(readlink "$dest_file")")" = "$(winpath "$src_file")" ]; then
            echo "Symlink already correct for $dest_file"
            return 0
        fi

        echo "Backing up existing $dest_file to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        mv "$dest_file" "$BACKUP_DIR/"
    fi

    mkdir -p "$(dirname "$dest_file")"
    echo "Creating symlink $dest_file -> $src_file"
    ln -s "$src_file" "$dest_file"
}

# Neovim's config dir: $XDG_CONFIG_HOME/nvim if set, else ~/AppData/Local/nvim on
# Windows (%LOCALAPPDATA%), ~/.config/nvim elsewhere.
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

# WezTerm's config dir: $XDG_CONFIG_HOME/wezterm if set, else ~/.config/wezterm on
# every platform -- unlike Neovim it does NOT use AppData on Windows.
wezterm_config_dir() {
    if [ -n "${XDG_CONFIG_HOME:-}" ]; then
        printf '%s/wezterm' "$(printf '%s' "$XDG_CONFIG_HOME" | tr '\134' '/')"
    else
        printf '%s/wezterm' "$HOME/.config"
    fi
}

setup_dotfiles() {
    echo "Setting up dotfiles"

    setup_symlink "$DOTFILES_PATH/shellenv" "$HOME/.shellenv"
    # Migration: os_env was renamed to shellenv -- drop the dangling ~/.os_env
    # symlink older installs left (only if a symlink, never a real file).
    if [ -L "$HOME/.os_env" ]; then
        rm -f "$HOME/.os_env"
    fi
    setup_symlink "$DOTFILES_PATH/bashrc" "$HOME/.bashrc"
    setup_symlink "$DOTFILES_PATH/bashrc_linux" "$HOME/.bashrc_linux"
    setup_symlink "$DOTFILES_PATH/bashrc_macos" "$HOME/.bashrc_macos"
    setup_symlink "$DOTFILES_PATH/bashrc_windows" "$HOME/.bashrc_windows"
    setup_symlink "$DOTFILES_PATH/bash_profile" "$HOME/.bash_profile"
    setup_symlink "$DOTFILES_PATH/nvim" "$(nvim_config_dir)"
    setup_symlink "$DOTFILES_PATH/wezterm" "$(wezterm_config_dir)"
    setup_symlink "$DOTFILES_PATH/bash_aliases" "$HOME/.bash_aliases"
    setup_symlink "$DOTFILES_PATH/gitconfig" "$HOME/.gitconfig"

    # jai(1) config all lives under ~/.jai/. Link each file in jai/ into ~/.jai/,
    # except jairc which the tool reads as the dotted ~/.jai/.jairc.
    for src in "$DOTFILES_PATH/jai/"*; do
        [ -e "$src" ] || continue
        if [ "$(basename "$src")" = "jairc" ]; then
            setup_symlink "$src" "$HOME/.jai/.jairc"
        else
            setup_symlink "$src" "$HOME/.jai/$(basename "$src")"
        fi
    done

    echo "Successfully set up dotfiles"
}

# Set up one agent's home: <label> <repo-subdir> <dest-dir> <instructions-name>.
# Symlinks each tracked entry from <repo-subdir>/ into <dest-dir>/. Only config
# lives in <repo-subdir>/; the rest of <dest-dir> (credentials, history,
# sessions, jobs -- all runtime state) is left alone. Then links the shared
# global instructions in under the name that agent expects.
setup_agent() {
    local label="$1" repo_subdir="$2" dest_dir="$3" instructions_name="$4"

    echo "Setting up $label config"

    for src in "$DOTFILES_PATH/$repo_subdir/"*; do
        [ -e "$src" ] || continue
        setup_symlink "$src" "$dest_dir/$(basename "$src")"
    done

    # Global instructions are shared across all agents (one source of truth in
    # shared/); each agent reads them under the name it expects.
    setup_symlink "$DOTFILES_PATH/shared/agent-instructions.md" "$dest_dir/$instructions_name"

    echo "Successfully set up $label config"
}

# Warn to stderr with a uniform prefix. Used by setup_pyenv, setup_completions,
# and the sourced init_<os>.sh hooks (defined before they're sourced below).
warn() {
    echo "Warning: $*" >&2
}

# Surface common user-level tool dirs so the opportunistic steps below find a tool
# you installed there but that isn't on this non-interactive shell's PATH (the
# uv/starship installers use ~/.local/bin; rustup/cargo use ~/.cargo/bin).
# path_prepend no-ops on missing dirs. init.sh installs nothing -- it's config-only.
ensure_tools_on_path() {
    path_prepend "$HOME/.local/bin"
    path_prepend "${XDG_BIN_HOME:-$HOME/.local/bin}"
    path_prepend "${CARGO_HOME:-$HOME/.cargo}/bin"
}

setup_pyenv() {
    # uv's activate script is under Scripts/ on Windows, bin/ on Unix.
    local activate="$HOME/py313/bin/activate"
    [ "$SYSTEM_OS" = "Windows" ] && activate="$HOME/py313/Scripts/activate"

    if [ -e "$activate" ]; then
        echo "Virtual env already set up"
        echo "run pyenv to activate"
        return
    fi

    # uv is user-installed (config-only). If it's missing, skip the venv rather
    # than abort under set -e (symlinks are already done), like setup_completions.
    if ! have_cmd uv; then
        echo "uv not found; skipping venv." \
             "Install uv (or re-run init.sh in a new shell) to create it."
        return
    fi

    echo "Setting up pyenv"
    # Best-effort: `uv venv` fetches a CPython build, so a network failure warns
    # rather than aborts (setup_completions still runs after).
    if uv venv "$HOME/py313" --seed --python 3.13; then
        echo "Pyenv setup"
        echo "run pyenv to activate"
    else
        warn "'uv venv' failed; skipping. Re-run init.sh to retry."
    fi
}

# Generate bash completions into the user completions dir, where bash-completion
# lazy-loads each on first TAB (no shell-startup cost). Gate each on its command
# existing, so an absent tool produces no file. Re-run to refresh after upgrades.
setup_completions() {
    echo "Generating bash completions"
    local dir="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
    mkdir -p "$dir"

    # gen_completion <cmd> <generator...>: file named after the looked-up command
    # (the generator can differ -- cargo's comes from rustup). Write .tmp then mv
    # so a failed generation leaves no empty file shadowing the real completion.
    gen_completion() {
        local cmd="$1"; shift
        have_cmd "$cmd" || return 0
        if "$@" > "$dir/$cmd.tmp" 2>/dev/null; then
            mv "$dir/$cmd.tmp" "$dir/$cmd"
        else
            rm -f "$dir/$cmd.tmp"
            warn "could not generate $cmd completion"
        fi
    }

    gen_completion uv     uv  generate-shell-completion bash
    gen_completion uvx    uvx --generate-shell-completion bash
    gen_completion pixi   pixi completion --shell bash
    gen_completion rustup rustup completions bash
    gen_completion cargo  rustup completions bash cargo

    echo "Completions written to $dir"
}

# Per-OS extra setup hook. Default no-op; a present init_<os>.sh may override it.
# Runs as a step below.
setup_os() {
    :
}

# Source per-OS overrides (setup_os, env like MSYS) after the defaults so they can
# override, but before the steps run. Repo copy: ~/.* symlinks may not exist yet.
os_init="$DOTFILES_PATH/init_$(printf '%s' "$SYSTEM_OS" | tr '[:upper:]' '[:lower:]').sh"
if [ -f "$os_init" ]; then
    . "$os_init"
fi

setup_dotfiles
setup_agent "Claude" claude                  "$HOME/.claude"                 CLAUDE.md
setup_agent "Codex"  codex                   "$HOME/.codex"                  AGENTS.md
setup_agent "Agy"    gemini/antigravity-cli  "$HOME/.gemini/antigravity-cli" AGENTS.md
setup_os
ensure_tools_on_path
setup_pyenv
setup_completions

# Don't source ~/.bashrc here: this runs in its own non-interactive subshell, so
# nothing it sets could propagate to the parent shell. Reload it yourself.
echo
echo "Done. Open a new shell or run:  source ~/.bashrc"
