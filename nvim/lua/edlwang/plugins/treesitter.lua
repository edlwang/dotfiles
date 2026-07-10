return {
	"nvim-treesitter/nvim-treesitter",
	-- Load just before the first file renders so highlighting is ready without a
	-- flash, but isn't paid on an empty/dashboard startup.
	event = { "BufReadPre", "BufNewFile" },
	branch = "main",
	build = ":TSUpdate",
	config = function()
		-- main branch: no more require("nvim-treesitter.configs").setup{}. Parsers
		-- are installed via install() (async; returns immediately), and highlight/
		-- indent are enabled per-buffer from a FileType autocmd below.
		require("nvim-treesitter").install({
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
		})

		-- Enable treesitter highlighting + indentation per buffer. We deliberately
		-- do NOT scope the autocmd to the list above: a filetype's name doesn't
		-- always match its parser (e.g. markdown_inline), and auto_install no
		-- longer exists, so guarding vim.treesitter.start() with pcall is both
		-- cleaner and more robust — it's a harmless no-op for filetypes without an
		-- installed parser, and indentexpr is only set when a parser attached.
		vim.api.nvim_create_autocmd("FileType", {
			callback = function()
				if pcall(vim.treesitter.start) then
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
