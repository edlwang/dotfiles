return {
	"mbbill/undotree",
	lazy = false,
	config = function()
		-- The <leader>tu keymap lives in editor/keybinds.lua
		vim.g.undotree_WindowLayout = 3
		print("Loaded undotree config")
	end,
}
