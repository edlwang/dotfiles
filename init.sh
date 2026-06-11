#!/bin/bash
set -euo pipefail

DOTFILES_PATH="$HOME/dotfiles"
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

        echo "Backuping up existing $dest_file to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        mv "$dest_file" "$BACKUP_DIR/"
    fi

    # Create symlink
    mkdir -p "$(dirname "$dest_file")"
    echo "Creating symlink $dest_file -> $src_file"
    ln -s "$src_file" "$dest_file"
}

setup_dotfiles() {
    echo "Setting up dotfiles"

    setup_symlink "$DOTFILES_PATH/bashrc" "$HOME/.bashrc"
    setup_symlink "$DOTFILES_PATH/bash_profile" "$HOME/.bash_profile"
    setup_symlink "$DOTFILES_PATH/nvim" "$HOME/.config/nvim"
    setup_symlink "$DOTFILES_PATH/bash_aliases" "$HOME/.bash_aliases"
    setup_symlink "$DOTFILES_PATH/gitconfig" "$HOME/.gitconfig"

    echo "Successfull setup dotfiles"
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
install_starship
install_uv
setup_pyenv
. "$HOME/.bashrc"



