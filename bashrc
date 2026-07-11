# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
#

# Detect OS (sets SYSTEM_OS) and load shared helpers (have_cmd, winpath,
# path_prepend) — see shellenv. The rest of this file depends on those helpers,
# so a missing ~/.shellenv (dotfiles not installed yet, or a broken symlink)
# must fail loudly here rather than degrade into a pile of "command not found"
# errors further down. bashrc is sourced, so `return` just stops this file.
if [ -f "$HOME/.shellenv" ]; then
    . "$HOME/.shellenv"
else
    echo "bashrc: ~/.shellenv missing or broken; run the dotfiles init.sh." \
         "Skipping shell config." >&2
    return
fi

# Pull in the system-wide bashrc where the distro keeps one at this path
# (Fedora/RHEL family, macOS). There it's what runs /etc/profile.d/*.sh for
# non-login interactive shells -- e.g. the Homebrew shellenv and terminal cwd
# tracking -- which a bare ~/.bashrc (like a WezTerm pane) would otherwise miss.
# Mirrors the stock Fedora ~/.bashrc. Debian keeps its system file at
# /etc/bash.bashrc (auto-sourced by interactive bash), so the -f test correctly
# no-ops there. Sourced before our own settings below so starship's prompt and
# the HIST*/PATH tweaks further down win.
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Source platform-specific config so OS-only code stays out of this shared
# bashrc. Each platform has its own ~/.bashrc_<os> file, named by the lowercased
# SYSTEM_OS (the same convention init.sh uses for init_<os>.sh). Done early
# (before the interactive guard below) so things like the Windows HOME fix
# always run; a missing file (e.g. SYSTEM_OS=Unknown) is skipped by the -f test.
os_rc="$HOME/.bashrc_$(printf '%s' "$SYSTEM_OS" | tr '[:upper:]' '[:lower:]')"
[ -f "$os_rc" ] && . "$os_rc"
unset os_rc

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
have_cmd lesspipe && eval "$(SHELL=/bin/sh lesspipe)"

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
  if have_cmd "$ed"; then
    export EDITOR="$ed" VISUAL="$ed"
    break
  fi
done
unset ed  # don't leak the loop temporary (cf. os_rc above)

# WezTerm shell integration. Emits OSC 7 (the current working directory) on every
# prompt -- plus OSC 133 semantic zones and user vars -- so WezTerm opens new
# splits/tabs in the *current* pane's directory instead of $HOME. The splits
# already spawn in CurrentPaneDomain, but that only inherits the cwd if the shell
# reports it; the distro's own emitter (vte.sh / systemd) isn't present on every
# platform and gets dropped once starship owns the prompt, so use WezTerm's own
# script. Vendored verbatim under wezterm/ (see README -> WezTerm for how to
# refresh it); its OSC sequences are terminal-agnostic and ignored elsewhere, so
# sourcing it unconditionally is safe. Source it BEFORE starship: it pulls in
# bash-preexec, which starship then cooperates with (precmd_functions) rather than
# fighting over PROMPT_COMMAND.
wezterm_integration="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/shell-integration.sh"
[ -f "$wezterm_integration" ] && . "$wezterm_integration"
unset wezterm_integration

# Use starship if available; otherwise fall back to a simple, portable prompt
# (user@host:dir). starship is the real prompt (you install it), so this branch
# only matters on a machine without it. Color when $TERM advertises it.
if have_cmd starship; then
    eval "$(starship init bash)"
else
    case "$TERM" in
        xterm-color|*-256color)
            PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ ';;
        *)
            PS1='\u@\h:\w\$ ';;
    esac
fi

# Flush this shell's history to $HISTFILE after every prompt, not just at exit
# (histappend above still covers a clean exit) -- so history survives a crash
# and is available to freshly-opened panes. Deliberately `history -a` (append
# only), not `history -n` (merge in other panes' history): re-reading other
# panes' commands into a *live* pane's history would interleave unrelated
# sessions into `history`/up-arrow recall, which is worse than losing a few
# commands to a crash. Requires bash-preexec's precmd_functions array (set up
# by the WezTerm integration block above); silently a no-op if that's not
# available (e.g. no WezTerm on this machine and starship falls back to plain
# PROMPT_COMMAND). Guarded against re-registering on a re-source.
_persist_history() { history -a; }
if declare -p precmd_functions &>/dev/null; then
    already_registered=0
    for precmd_fn in "${precmd_functions[@]}"; do
        [ "$precmd_fn" = "_persist_history" ] && already_registered=1 && break
    done
    [ "$already_registered" -eq 0 ] && precmd_functions+=(_persist_history)
    unset already_registered precmd_fn
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

# PATH priorities, asserted last so they win over the tool-env scripts above
# (uv's ~/.local/bin/env, ~/.cargo/env). path_prepend (from shellenv) moves a dir
# to the front if it exists, so the last call wins and re-sourcing is idempotent.
path_prepend "$HOME/.pixi/bin"
path_prepend "$HOME/.local/bin"   # last call = highest priority

# Source local bashrc override (mirrors ~/.gitconfig.local pattern)
if [ -f "$HOME/.bashrc_local" ]; then
    . "$HOME/.bashrc_local"
fi
