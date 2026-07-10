return { -- Autoformat
	"stevearc/conform.nvim",
	event = "BufWritePre",
	cmd = "ConformInfo",
	-- The <leader>cf format keymap lives in editor/keybinds.lua.
	opts = {
		notify_on_error = false,
		format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
		-- Filetype → formatters. A value can be a list to run sequentially, or a
		-- sub-list to run the first available (e.g. { { "prettierd", "prettier" } }).
		formatters_by_ft = {
			lua = { "stylua" },
		},
	},
}
