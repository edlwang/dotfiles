# Shared by Linux setup and doctor. The callback receives the repository
# source, installed destination, and optional backup subdirectory.
for_each_linux_desktop_link() {
    local callback="$1" config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
    local source destination backup_subdir

    # Fields are repo path, XDG-relative path, and backup subdirectory.
    # An empty third field uses the backup root.
    # Waybar prefers config to config.jsonc.
    while IFS='|' read -r source destination backup_subdir <&3; do
        "$callback" "$DOTFILES_PATH/$source" "$config_dir/$destination" "$backup_subdir"
    done 3<<'LINKS'
sway/config|sway/config|
swaylock/config|swaylock/config|swaylock
fuzzel/fuzzel.ini|fuzzel/fuzzel.ini|
nmtui/palette|nmtui/palette|nmtui
swaync/config.json|swaync/config.json|swaync
swaync/style.css|swaync/style.css|swaync
waybar/config.jsonc|waybar/config|waybar
waybar/style.css|waybar/style.css|waybar
waybar/gpu.py|waybar/gpu.py|waybar
waybar/nightlight.sh|waybar/nightlight.sh|waybar
LINKS
}
