return {
	-- Shows a popup of available keybindings as you type a prefix.
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		-- Group labels for the leader prefixes used in editor/keybinds.lua
		spec = {
			{ "<leader>c", group = "code" },
			{ "<leader>e", group = "explore" },
			{ "<leader>f", group = "find" },
			{ "<leader>g", group = "git" },
			{ "<leader>h", group = "harpoon" },
			{ "<leader>w", group = "window" },
			{ "<leader>t", group = "toggle" },
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer local keymaps (which-key)",
		},
	},
}
