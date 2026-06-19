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
}
