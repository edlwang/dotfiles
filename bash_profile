# Login shells read ~/.bash_profile instead of ~/.bashrc; source ~/.bashrc here
# so login shells (macOS terminals, the `bash -l` WezTerm launches on Windows)
# load the same interactive config as non-login ones.
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
