return { -- Autoformat
	"stevearc/conform.nvim",
	event = "BufWritePre",
	cmd = "ConformInfo",
	-- The <leader>cf format keymap lives in editor/keybinds.lua.
	opts = {
		notify_on_error = false,
		format_on_save = function(bufnr)
			-- Per-filetype opt-out of format-on-save, for languages without a
			-- well-standardized style. Empty for now (nothing opted out).
			local disable_filetypes = {}
			return {
				timeout_ms = 500,
				lsp_format = not disable_filetypes[vim.bo[bufnr].filetype] and "fallback" or "never",
			}
		end,
		-- Filetype → formatters. A value can be a list to run sequentially, or a
		-- sub-list to run the first available (e.g. { { "prettierd", "prettier" } }).
		formatters_by_ft = {
			lua = { "stylua" },
		},
	},
}
