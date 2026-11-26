# Linux-specific setup, sourced by init.sh when SYSTEM_OS=Linux.

setup_os() {
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
    local sway_dir="$config_dir/sway"
    local local_conf="$sway_dir/local.conf"

    setup_symlink "$DOTFILES_PATH/sway/config" "$sway_dir/config"
    # Keep both files when backing up the two configs in the same run.
    BACKUP_DIR="$BACKUP_DIR/swaylock" setup_symlink "$DOTFILES_PATH/swaylock/config" "$config_dir/swaylock/config"
    setup_symlink "$DOTFILES_PATH/fuzzel/fuzzel.ini" "$config_dir/fuzzel/fuzzel.ini"

    if [ ! -e "$local_conf" ] && [ ! -L "$local_conf" ]; then
        echo "Copying Sway local config template to $local_conf"
        cp -nT -- "$DOTFILES_PATH/sway/local.conf.example" "$local_conf"
    fi
}
