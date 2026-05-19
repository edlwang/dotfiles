-- handle remaps and keybinds
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set("n", "<leader>ex", vim.cmd.Ex)

-- moving selections
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- half page jumping center cursor
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- keep search terms in middle
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- paste over keeping register same
vim.keymap.set("x", "<leader>p", '"_dp')

-- copy to clipboard
vim.keymap.set("n", "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')
vim.keymap.set("v", "<leader>y", '"+y')

-- delete to null register
vim.keymap.set("n", "<leader>d", '"_d')
vim.keymap.set("v", "<leader>d", '"_d')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- indent file
vim.keymap.set("n", "<leader>li", "<S-g>vgg=")

-- toggle wrap
vim.keymap.set("n", "<leader>ww", ":set wrap!<enter>")

-- window resizing
vim.keymap.set("n", "<leader>wk", "<C-w>+")
vim.keymap.set("n", "<leader>wj", "<C-w>-")
vim.keymap.set("n", "<leader>wl", "<C-w>>")
vim.keymap.set("n", "<leader>wh", "<C-w><")

-- line appending
vim.keymap.set("n", "J", "mzJ`z")

print("Loaded keybind settings")
