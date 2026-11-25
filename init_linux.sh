# Linux-specific setup, sourced by init.sh when SYSTEM_OS=Linux.

setup_os() {
    setup_symlink "$DOTFILES_PATH/sway/config" "${XDG_CONFIG_HOME:-$HOME/.config}/sway/config"
}
