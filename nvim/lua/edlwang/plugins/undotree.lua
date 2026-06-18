return {
	"mbbill/undotree",
	-- The <leader>tu keymap (in editor/keybinds.lua) runs :UndotreeToggle.
	cmd = "UndotreeToggle",
	init = function()
		vim.g.undotree_WindowLayout = 3
	end,
}
