return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("lualine").setup({
			options = {
				theme = "dracula", -- intentionally not tokyonight, i think dracula line looks better
			},
		})
	end,
}
