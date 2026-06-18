local M = {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	branch = "master",
	build = ":TSUpdate",
	config = function()
		local configs = require("nvim-treesitter.configs")
		configs.setup({
			highlight = { enable = true },
			indent = { enable = true },
			-- Install any parser that isn't listed below on first use of its filetype
			auto_install = true,
			ensure_installed = {
				"lua",
				"python",
				"rust",
				"html",
				"json",
				"markdown",
				"markdown_inline",
				-- latex intentionally omitted: vimtex handles LaTeX, and the
				-- latex parser needs the tree-sitter CLI to be generated
				"bash",
				"vim",
				"vimdoc",
			},
		})
	end,
}

return { M }
