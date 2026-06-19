-- change backup and undo settings
vim.opt.swapfile = false
vim.opt.backup = false
-- Use expand("~") rather than os.getenv("HOME"): on Windows $HOME is unset when
-- nvim is launched outside the Git Bash login shell (PowerShell, cmd, a GUI/IDE,
-- "Edit with Neovim"), and os.getenv would return nil -> the concat errors out
-- and aborts the whole init. expand("~") resolves the home dir on every platform
-- (falling back to USERPROFILE on Windows), keeping the same ~/.vim/undodir path.
vim.opt.undodir = vim.fn.expand("~/.vim/undodir")
vim.opt.undofile = true
