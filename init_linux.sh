# Linux-specific setup, sourced by init.sh when SYSTEM_OS=Linux.

setup_os() {
    local sway_dir="${XDG_CONFIG_HOME:-$HOME/.config}/sway"
    local local_conf="$sway_dir/local.conf"

    setup_symlink "$DOTFILES_PATH/sway/config" "$sway_dir/config"

    if [ ! -e "$local_conf" ] && [ ! -L "$local_conf" ]; then
        echo "Copying Sway local config template to $local_conf"
        cp -nT -- "$DOTFILES_PATH/sway/local.conf.example" "$local_conf"
    fi
}
