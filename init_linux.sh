# Linux-specific setup, sourced by init.sh when SYSTEM_OS=Linux.

. "$DOTFILES_PATH/linux_desktop_links.sh"

setup_linux_desktop_link() {
    local source="$1" destination="$2" backup_subdir="$3"
    BACKUP_DIR="$BACKUP_DIR${backup_subdir:+/$backup_subdir}" setup_symlink "$source" "$destination"
}

setup_os() {
    local local_conf="${XDG_CONFIG_HOME:-$HOME/.config}/sway/local.conf"

    for_each_linux_desktop_link setup_linux_desktop_link

    if [ ! -e "$local_conf" ] && [ ! -L "$local_conf" ]; then
        echo "Copying Sway local config template to $local_conf"
        cp -nT -- "$DOTFILES_PATH/sway/local.conf.example" "$local_conf"
    fi
}
