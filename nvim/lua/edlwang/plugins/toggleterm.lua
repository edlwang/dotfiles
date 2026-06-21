return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		-- The open mapping (<leader>tt) is registered inside setup() below, so unlike
		-- telescope/harpoon there's no require() to hook — give it explicit triggers.
		-- lazy.nvim loads the plugin on first <leader>tt press, then replays the key.
		cmd = { "ToggleTerm", "ToggleTermToggleAll", "TermExec" },
		keys = [[<leader>tt]],
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
