# Linux-specific install logic, sourced by init.sh when SYSTEM_OS=Linux.
# Overrides the default no-op setup_os; runs as a setup step below.

# Install a user-level WezTerm desktop entry that launches the GUI via
# `connect unix` so windows attach to the persistent mux server. WezTerm's
# config sets default_gui_startup_args = {"connect","unix"}, but that only
# applies when wezterm-gui is launched with NO subcommand. The distro entry
# (/usr/share/applications/org.wezfurlong.wezterm.desktop) hardcodes
# `Exec=wezterm start --cwd .`, whose explicit `start` overrides the default
# args, so its windows open on the non-persistent local domain. A user entry of
# the same name shadows the system one, restoring persistence the way the
# no-subcommand launch already does on Windows.
setup_os() {
    local apps_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"

    # A user entry shadows the system one only if it shares its basename. Match
    # whatever the distro calls it (deb/rpm/Arch use org.wezfurlong.wezterm,
    # but others may differ), falling back to the upstream name if none is
    # installed yet.
    local name=org.wezfurlong.wezterm.desktop
    local f
    for f in /usr/share/applications/*wezterm*.desktop; do
        [ -e "$f" ] && { name="$(basename "$f")"; break; }
    done

    setup_symlink "$DOTFILES_PATH/wezterm/org.wezfurlong.wezterm.desktop" \
        "$apps_dir/$name"

    # Refresh the desktop-entry cache so launchers pick up the override. Not
    # required for the entry to work and absent on minimal installs, so don't
    # let its absence or failure abort the script (set -e is on).
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$apps_dir" >/dev/null 2>&1 || true
    fi

    bind_terminal_shortcut
}

# Point GNOME's Ctrl+Alt+T at the persistent mux. The .desktop override above
# only fixes the applications-list launcher; the keyboard shortcut is GNOME's
# media-keys "terminal" action, which launches x-terminal-emulator instead of
# the .desktop entry. On Ubuntu that alternative is the package's
# open-wezterm-here (`exec wezterm start --cwd ...`), whose explicit `start`
# overrides default_gui_startup_args = {"connect","unix"}, so its window lands
# on the non-persistent local domain -- the same failure the .desktop override
# solved. Rather than fight the root-owned alternative, take over the shortcut
# at the user level: a GNOME custom keybinding running the same
# `wezterm-gui connect unix` the .desktop entry uses, plus unbinding the
# built-in terminal action so it can't double-fire on the same chord.
#
# This is the one place init writes live user settings (dconf) rather than
# symlinking a tracked file -- see AGENTS.md. All per-user, no root; silently
# skips on non-GNOME desktops, where the schema is absent and the shortcut
# would need that DE's own mechanism anyway.
bind_terminal_shortcut() {
    command -v gsettings >/dev/null 2>&1 || return 0

    local mk='org.gnome.settings-daemon.plugins.media-keys'
    # Skip if the schema isn't installed (non-GNOME session). list-schemas
    # omits relocatable schemas, so check the plain media-keys schema, which
    # the custom-keybinding relocatable schema ships alongside.
    gsettings list-schemas 2>/dev/null | grep -qx "$mk" || return 0

    local path='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/wezterm-mux/'
    local ckb="${mk}.custom-keybinding:$path"

    gsettings set "$ckb" name 'WezTerm (mux)'
    gsettings set "$ckb" command 'wezterm-gui connect unix'
    gsettings set "$ckb" binding '<Primary><Alt>t'

    # Register our keybinding path in the list if absent. The list is an `as`;
    # append to whatever's there rather than clobbering other custom shortcuts.
    local list
    list=$(gsettings get "$mk" custom-keybindings)
    case "$list" in
        *"'$path'"*) ;;                                                       # already registered
        '@as []'|'[]') gsettings set "$mk" custom-keybindings "['$path']";;
        *) gsettings set "$mk" custom-keybindings "${list%]*}, '$path']";;
    esac

    # Free Ctrl+Alt+T from the built-in terminal action so our binding owns it.
    # Guarded: upstream (non-Ubuntu) GNOME may not ship the `terminal` key, and
    # setting a missing key would abort under set -e.
    if gsettings list-keys "$mk" 2>/dev/null | grep -qx terminal; then
        gsettings set "$mk" terminal "@as []"
    fi
}
