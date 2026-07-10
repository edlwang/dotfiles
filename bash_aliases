# OS-specific aliases (e.g. ls, pyenv) live in the per-platform
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
jaicl() { _jai claude "$@"; }
jaico() { _jai codex "$@"; }
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

# cd using pushd, popd goes back, vdirs lists the stack. pushd always needs a
# target, so default to $HOME when called with no args (plain `cd`).
cd() {
    builtin pushd "${@:-$HOME}" > /dev/null
}

# List the directory stack newest-first (like `dirs -v`), but capped so a
# long-lived stack stays readable: `vdirs` shows the top 10, `vdirs N` the top
# N, `vdirs all` the whole stack.
vdirs() {
    case "$1" in
        all|-a) dirs -v ;;
        *)      dirs -v | head -n "${1:-10}" ;;
    esac
}
