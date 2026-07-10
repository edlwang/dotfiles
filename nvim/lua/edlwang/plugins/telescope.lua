return {
	"nvim-telescope/telescope.nvim",
	-- Lazy-load on the :Telescope command. The keymaps in editor/keybinds.lua
	-- call require("telescope.builtin"), which lazy.nvim's require hook also
	-- uses to load the plugin on first use, so there's nothing to load eagerly.
	cmd = "Telescope",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-telescope/telescope-ui-select.nvim",
	},
	config = function()
		require("telescope").setup({
			extensions = {
				fzf = {},
				["ui-select"] = {
					require("telescope.themes").get_dropdown({}),
				},
			},
		})
		require("telescope").load_extension("fzf")
		require("telescope").load_extension("ui-select")
		-- Telescope keymaps live in editor/keybinds.lua.
	end,
}
