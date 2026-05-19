return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		config = function()
			require("toggleterm").setup({
				open_mapping = [[<leader>t]],
				terminal_mappings = false,
				insert_mappings = false,
			})
			vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], {})
		end,
	},
}
