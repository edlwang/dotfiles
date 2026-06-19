# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
#

# Detect OS (sets SYSTEM_OS). Shared with init.sh — see os_env.
if [ -f "$HOME/.os_env" ]; then
    . "$HOME/.os_env"
fi

# Source platform-specific config so OS-only code stays out of this shared
# bashrc. Each platform has its own ~/.bashrc_<os> file. Done early (before
# the interactive guard below) so things like the Windows HOME fix always run.
case "$SYSTEM_OS" in
    Linux)   [ -f "$HOME/.bashrc_linux" ]   && . "$HOME/.bashrc_linux";;
    macOS)   [ -f "$HOME/.bashrc_macos" ]   && . "$HOME/.bashrc_macos";;
    Windows) [ -f "$HOME/.bashrc_windows" ] && . "$HOME/.bashrc_windows";;
esac

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=200000
HISTTIMEFORMAT='%F %T '

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  elif [ -f /opt/homebrew/etc/profile.d/bash_completion.sh ]; then
    # macOS Homebrew support
    . /opt/homebrew/etc/profile.d/bash_completion.sh
  fi
fi


# Load environment variables
if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi

# Set editor to the first one available, preferring nvim.
for ed in nvim vim vi; do
  if command -v "$ed" >/dev/null 2>&1; then
    export EDITOR="$ed" VISUAL="$ed"
    break
  fi
done
unset ed  # don't leak the loop temporary (cf. os_rc above)

# Use starship if available; otherwise fall back to a simple, portable prompt
# (user@host:dir). starship is the real prompt — installed by init.sh — so this
# branch only matters on a machine without it; keep it minimal. Color when $TERM
# advertises it, plain otherwise.
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
else
    case "$TERM" in
        xterm-color|*-256color)
            PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ ';;
        *)
            PS1='\u@\h:\w\$ ';;
    esac
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f "$HOME/.bash_aliases" ]; then
    . "$HOME/.bash_aliases"
fi

# Load Rust/cargo environment if installed
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# PATH priorities, asserted last so they win over whatever the tool-env scripts
# above (uv's ~/.local/bin/env, ~/.cargo/env) already put on PATH. path_prepend
# moves a directory to the FRONT of PATH (dropping any earlier occurrence) when
# it exists, so the last call wins and re-sourcing this file is idempotent.
path_prepend() {
    [ -d "$1" ] || return
    local p=":${PATH}:"
    p="${p//:$1:/:}"        # drop any existing occurrence
    p="${p#:}"; p="${p%:}"  # trim the framing colons
    export PATH="$1${p:+:$p}"
}
path_prepend "$HOME/.pixi/bin"
path_prepend "$HOME/.local/bin"   # last call = highest priority
