return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	-- No command/event trigger; the require("harpoon") calls in editor/keybinds.lua
	-- load it on first use via lazy.nvim's require hook.
	lazy = true,
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		-- Harpoon keymaps live in editor/keybinds.lua
		require("harpoon"):setup()
	end,
}
