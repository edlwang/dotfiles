return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- file-type icons (optional but recommended)
			"MunifTanjim/nui.nvim",
		},
		-- Neo-tree keymap lives in editor/keybinds.lua.
		opts = {
			-- The global sidescrolloff = 20 (editor/misc.lua) plus nowrap makes the
			-- narrow tree window scroll horizontally on long names. Pin it to 0
			-- window-locally so the tree stays aligned to the left edge.
			event_handlers = {
				{
					event = "neo_tree_buffer_enter",
					handler = function()
						vim.opt_local.sidescrolloff = 0
					end,
				},
			},
			filesystem = {
				filtered_items = {
					visible = true,
				},
			},
		},
	},
}
