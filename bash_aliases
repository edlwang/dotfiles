# OS-specific aliases (e.g. ls, pyenv) live in the per-platform
# ~/.bashrc_<os> files, sourced by bashrc.

# bashrc
alias sbrc="source ~/.bashrc"
alias ebrc="$EDITOR ~/.bashrc"

# cd using pushd, popd goes back, dirs -v lists stack
cd() {
    if [ $# -eq 0 ]; then
        builtin pushd ~ > /dev/null
    else
        builtin pushd "$@" > /dev/null
    fi
}
alias vdirs="dirs -v"
