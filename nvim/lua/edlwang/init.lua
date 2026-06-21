-- Leader must be set before anything that defines mappings loads, so it lives
-- here (single source of truth) ahead of editor/ and lazy.nvim.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("edlwang.editor")
require("edlwang.lazy")
