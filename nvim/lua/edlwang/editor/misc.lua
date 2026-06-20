-- Editor settings that don't warrant their own module.
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 20 -- neo-tree pins this to 0 window-locally (plugins/neotree.lua)
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@") -- treat '@' as a filename char so `gf` follows user@host paths
vim.opt.colorcolumn = "80"
-- Lowered from the defaults (4000/1000 ms) so CursorHold-driven LSP highlights
-- and the which-key popup feel responsive.
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
