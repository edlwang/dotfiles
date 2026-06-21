# Linux-specific setup, sourced by init.sh when SYSTEM_OS=Linux. Overrides the
# no-op setup_os hook with the WezTerm desktop entry + GNOME Ctrl+Alt+T shortcut.
# (init.sh is config-only -- install tools yourself; see README.)

# Match a producer's output: `producer | pipe_match -x foo`. Plain grep, NOT
# grep -q: under pipefail, -q exits on first match and SIGPIPEs the producer, a
# false pipeline failure. Args pass straight to grep (e.g. -i, -x).
pipe_match() {
    grep "$@" >/dev/null 2>&1
}

# Install a user-level WezTerm desktop entry that launches via `connect unix` so
# windows attach to the persistent mux. WezTerm's default_gui_startup_args only
# apply with NO subcommand, but the distro entry hardcodes `wezterm start --cwd .`
# -- the explicit `start` overrides them, opening on the non-persistent local
# domain. A user entry of the same name shadows it, restoring persistence.
setup_os() {
    local apps_dir="${XDG_DATA_HOME:-$HOME/.local/share}/applications"

    # A user entry shadows the system one only if it shares its basename. Match
    # whatever the distro calls it, falling back to the upstream name.
    local name=org.wezfurlong.wezterm.desktop
    local f
    for f in /usr/share/applications/*wezterm*.desktop; do
        [ -e "$f" ] && { name="$(basename "$f")"; break; }
    done

    setup_symlink "$DOTFILES_PATH/wezterm/org.wezfurlong.wezterm.desktop" \
        "$apps_dir/$name"

    # Refresh the desktop-entry cache. Absent on minimal installs and not required
    # for the entry to work, so don't let it abort the script (set -e).
    if have_cmd update-desktop-database; then
        update-desktop-database "$apps_dir" >/dev/null 2>&1 || true
    fi

    bind_terminal_shortcut
}

# Point GNOME's Ctrl+Alt+T at the persistent mux. The .desktop override fixes the
# launcher, but the keyboard shortcut is GNOME's media-keys "terminal" action,
# which launches x-terminal-emulator (`wezterm start ...` on Ubuntu) -- same
# non-persistent failure. So take it over at the user level: a custom keybinding
# running `wezterm-gui connect unix`, plus unbinding the built-in terminal action.
# The one place init writes live dconf rather than a tracked file (see AGENTS.md);
# all per-user, no root; skips on non-GNOME desktops.
bind_terminal_shortcut() {
    have_cmd gsettings || return 0

    local mk='org.gnome.settings-daemon.plugins.media-keys'
    # Skip if the schema is absent (non-GNOME). list-schemas omits relocatable
    # schemas, so check the plain media-keys schema that ships alongside ours.
    gsettings list-schemas 2>/dev/null | pipe_match -x "$mk" || return 0

    local path='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/wezterm-mux/'
    local ckb="${mk}.custom-keybinding:$path"

    # The dconf writes are best-effort: any `gsettings set` can fail (schema
    # absent, or no writable dconf here) and would abort under set -e. gset warns
    # once, then the caller's `|| return` bails on the first failure.
    gset() {
        gsettings set "$@" && return 0
        warn "could not configure the WezTerm GNOME shortcut (dconf" \
             "write failed); leaving it unchanged."
        return 1
    }

    gset "$ckb" name 'WezTerm (mux)'               || return 0
    gset "$ckb" command 'wezterm-gui connect unix' || return 0
    gset "$ckb" binding '<Primary><Alt>t'          || return 0

    # Register our path in the keybinding list (an `as`) if absent, appending so
    # we don't clobber other custom shortcuts.
    local list
    list=$(gsettings get "$mk" custom-keybindings) || return 0
    case "$list" in
        *"'$path'"*) ;;                                                       # already registered
        '@as []'|'[]') gset "$mk" custom-keybindings "['$path']" || return 0 ;;
        *) gset "$mk" custom-keybindings "${list%]*}, '$path']" || return 0 ;;
    esac

    # Free Ctrl+Alt+T from the built-in terminal action so our binding owns it.
    # Guarded: non-Ubuntu GNOME may lack the `terminal` key (setting it would
    # abort under set -e); `|| warn` covers an unwritable dconf.
    if gsettings list-keys "$mk" 2>/dev/null | pipe_match -x terminal; then
        gsettings set "$mk" terminal "@as []" || \
            warn "could not clear GNOME's built-in terminal shortcut."
    fi
}
