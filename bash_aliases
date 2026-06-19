# OS-specific aliases (e.g. ls, pyenv) live in the per-platform
# ~/.bashrc_<os> files, sourced by bashrc.

# bashrc
alias sbrc="source ~/.bashrc"
alias ebrc='$EDITOR ~/.bashrc'

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
