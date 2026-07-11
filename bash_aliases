# OS-specific aliases (e.g. ls) live in the per-platform
# ~/.bashrc_<os> files, sourced by bashrc.

# bashrc
alias sbrc="source ~/.bashrc"
alias ebrc='$EDITOR ~/.bashrc'
alias edfs='$EDITOR ~/dotfiles'
# Sandbox launchers. Options before `--` go to jai (e.g. `jaicl -d dotfiles` to
# make the read-only dotfiles repo writable in-jail); args after `--` go to the
# agent (e.g. `jaicl -- --resume`). Bare `jaicl`/`jaico`/`jaiag` just launch.
_jai() {
    local jail="$1"; shift
    local opts=()
    while [[ $# -gt 0 && "$1" != "--" ]]; do
        opts+=("$1")
        shift
    done
    [[ "$1" == "--" ]] && shift
    # `--` terminates jai's own options so the jail name can never be swallowed
    # as the argument of a value-taking flag (a bare `jaicl -x` would otherwise
    # make jai read `claude` as `-x`'s DIR, drop the command, and launch the
    # default *casual* jail's shell instead of the claude jail).
    jai "${opts[@]}" -- "$jail" "$@"
}

# Codex has no config-file setting for a default named profile, and it rejects
# --profile for administrative commands that do not start a runtime. Return
# success only when the tracked default should be added to this invocation.
_codex_uses_default_profile() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            -p|--profile|--profile=*) return 1 ;;
        esac
    done

    case "${1:-}" in
        login|logout|plugin|mcp-server|app-server|remote-control|completion)
            return 1
            ;;
        update|doctor|apply|cloud|exec-server|features|help)
            return 1
            ;;
        debug)
            [[ "${2:-}" == "prompt-input" ]]
            ;;
        *)
            return 0
            ;;
    esac
}

# Apply the tracked profile to direct host launches when the command supports
# one; preserve explicit profile choices and unsupported administrative calls.
codex() {
    if _codex_uses_default_profile "$@"; then
        command codex --profile dotfiles "$@"
    else
        command codex "$@"
    fi
}

# jai starts the in-jail executable directly, so the shell function above does
# not cross the jail boundary. Preserve _jai's before/after-`--` interface while
# inserting the same default profile on the command side of that boundary.
_jaico() {
    local opts=()
    local profile_args=()

    while [[ $# -gt 0 && "$1" != "--" ]]; do
        opts+=("$1")
        shift
    done
    [[ "$1" == "--" ]] && shift

    if _codex_uses_default_profile "$@"; then
        profile_args=(--profile dotfiles)
    fi

    jai "${opts[@]}" -- codex "${profile_args[@]}" "$@"
}

jaicl() { _jai claude "$@"; }
jaico() { _jaico "$@"; }
jaiag() { _jai agy "$@"; }

# Activate a Python virtualenv: `svenv` uses ./.venv, `svenv <path>` uses
# <path>. Probes both the Unix (bin/activate) and Windows/MSYS
# (Scripts/activate) layouts. Returns non-zero (without exiting the shell) when
# neither exists.
svenv() {
    local venv="${1:-.venv}"
    local activate
    for activate in "$venv/bin/activate" "$venv/Scripts/activate"; do
        if [[ -f "$activate" ]]; then
            source "$activate"
            return
        fi
    done
    echo "svenv: no activate script under $venv (bin/ or Scripts/)" >&2
    return 1
}

# Activate the ~/py313 uv venv created by init.sh (svenv probes bin/ and Scripts/).
alias pyenv='svenv ~/py313'

# cd using pushd, popd goes back, vdirs lists the stack. pushd always needs a
# target, so default to $HOME when called with no args (plain `cd`).
cd() {
    if [[ "$1" == -* ]]; then
        builtin cd "$@"
    else
        builtin pushd "${@:-$HOME}" > /dev/null
    fi
}

# List the directory stack newest-first (like `dirs -v`), but capped so a
# long-lived stack stays readable: `vdirs` shows the top 10, `vdirs N` the top
# N, `vdirs all` the whole stack.
vdirs() {
    if [[ "$1" == "all" || "$1" == "-a" ]]; then
        dirs -v
    elif [[ -z "$1" || "$1" =~ ^[0-9]+$ ]]; then
        dirs -v | head -n "${1:-10}"
    else
        echo "vdirs: invalid argument '$1'" >&2
        return 1
    fi
}
