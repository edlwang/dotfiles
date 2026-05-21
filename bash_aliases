# System specific aliases
if [ "$SYSTEM_OS" = "Linux" ]; then
    alias ls='--color=auto'
elif [ "$SYSTEM_OS" = "macOS" ]; then
    alias ls='ls -G'
fi

# bashrc
alias sbrc="source ~/.bashrc"
alias ebrc="$EDITOR ~/.bashrc"

# pyenv
alias pyenv="source $HOME/py313/bin/activate"
