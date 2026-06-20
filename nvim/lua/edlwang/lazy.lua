-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- mapleader/maplocalleader are set in edlwang/init.lua, which runs before this.

require("lazy").setup({
	spec = {
		-- Auto-import every spec under lua/edlwang/plugins/ — adding a file there
		-- is all it takes to register a plugin; there's no central list.
		{ import = "edlwang.plugins" },
	},
	install = { colorscheme = { "tokyonight-moon" } },
	-- Check for plugin updates in the background, without a startup popup.
	checker = { enabled = true, notify = false },
	-- No plugin here uses luarocks; disabling it skips the hererocks bootstrap
	-- and silences the related :checkhealth warnings.
	rocks = { enabled = false },
})
