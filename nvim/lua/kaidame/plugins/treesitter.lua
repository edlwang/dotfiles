local M = {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	config = function()
		local configs = require("nvim-treesitter")
		configs.setup({
			highlight = { enable = true },
			indent = { enable = true },
			ensure_installed = {
				"lua",
				"python",
				"rust",
				"html",
			},
		})
	end,
	build = function()
		require("nvim-treesitter").update({ with_sync = true })()
	end,
}

return { M }
