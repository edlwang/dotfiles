return {
	"numToStr/Comment.nvim",
	-- Lazy-load on the comment keymaps instead of at startup. opts = {} is
	-- enough: lazy's default config runs require("Comment").setup(opts).
	keys = {
		{ "gcc", mode = "n", desc = "Comment toggle current line" },
		{ "gbc", mode = "n", desc = "Comment toggle current block" },
		{ "gc", mode = { "n", "x", "o" }, desc = "Comment toggle linewise" },
		{ "gb", mode = { "n", "x", "o" }, desc = "Comment toggle blockwise" },
		{ "gco", mode = "n", desc = "Comment insert below" },
		{ "gcO", mode = "n", desc = "Comment insert above" },
		{ "gcA", mode = "n", desc = "Comment insert end of line" },
	},
	opts = {},
}
