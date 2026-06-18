return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		-- Harpoon keymaps live in editor/keybinds.lua
		require("harpoon"):setup()
	end,
}
