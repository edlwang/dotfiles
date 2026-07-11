-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local clone_ok, clone_output = pcall(
		vim.fn.system,
		{ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath }
	)
	local clone_exit = vim.v.shell_error
	if not clone_ok or clone_exit ~= 0 or not (vim.uv or vim.loop).fs_stat(lazypath) then
		clone_output = vim.trim(tostring(clone_output))
		if #clone_output > 500 then
			clone_output = clone_output:sub(1, 500) .. "..."
		end

		local clone_status = clone_ok and string.format("git clone exit code %d", clone_exit)
			or "could not run git clone"
		local message = string.format(
			"Failed to bootstrap lazy.nvim at %s (%s). Verify Git is installed and network access to GitHub is available.",
			lazypath,
			clone_status
		)
		if clone_output ~= "" then
			message = message .. "\nGit output: " .. clone_output
		end
		error(message, 0)
	end
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
