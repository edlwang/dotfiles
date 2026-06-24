# OS-specific aliases (e.g. ls, pyenv) live in the per-platform
# ~/.bashrc_<os> files, sourced by bashrc.

# bashrc
alias sbrc="source ~/.bashrc"
alias ebrc='$EDITOR ~/.bashrc'
alias edfs='$EDITOR ~/dotfiles'
alias jaic='jai claude'

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
