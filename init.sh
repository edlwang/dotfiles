#!/bin/bash
set -euo pipefail

DOTFILES_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Detect OS (sets SYSTEM_OS) from the same file bashrc uses, so the installer
# and the shell never disagree. Source the repo copy: the ~/.os_env symlink
# may not exist yet on a first run.
. "$DOTFILES_PATH/os_env"

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

setup_dotfiles() {
    echo "Setting up dotfiles"

    setup_symlink "$DOTFILES_PATH/os_env" "$HOME/.os_env"
    setup_symlink "$DOTFILES_PATH/bashrc" "$HOME/.bashrc"
    setup_symlink "$DOTFILES_PATH/bashrc_linux" "$HOME/.bashrc_linux"
    setup_symlink "$DOTFILES_PATH/bashrc_macos" "$HOME/.bashrc_macos"
    setup_symlink "$DOTFILES_PATH/bashrc_windows" "$HOME/.bashrc_windows"
    setup_symlink "$DOTFILES_PATH/bash_profile" "$HOME/.bash_profile"
    setup_symlink "$DOTFILES_PATH/nvim" "$(nvim_config_dir)"
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

setup_pyenv() {
    if [ -e "$HOME/py313/bin/activate" ]; then
        echo "Virtual env already set up"
    else
        echo "Setting up pyenv"
        uv venv "$HOME/py313" --seed
        echo "Pyenv setup"
    fi
    echo "run pyenv to activate"
}

setup_dotfiles
setup_claude
install_starship
install_uv
setup_pyenv
. "$HOME/.bashrc"



