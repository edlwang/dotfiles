return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		config = function()
			-- The <esc> terminal-mode keymap lives in editor/keybinds.lua
			require("toggleterm").setup({
				open_mapping = [[<leader>tt]],
				terminal_mappings = false,
				insert_mappings = false,
			})
		end,
	},
}
