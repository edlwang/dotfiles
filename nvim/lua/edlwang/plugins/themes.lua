return {
	{
		"folke/tokyonight.nvim",
		lazy = false, -- load at startup; this is the active colorscheme
		priority = 1000, -- load before the other start plugins
		config = function()
			vim.cmd([[colorscheme tokyonight-moon]])
		end,
	},
}
