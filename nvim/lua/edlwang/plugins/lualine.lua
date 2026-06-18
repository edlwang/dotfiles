return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	opts = {
		options = {
			theme = "dracula", -- intentionally not tokyonight, i think dracula line looks better
		},
	},
}
