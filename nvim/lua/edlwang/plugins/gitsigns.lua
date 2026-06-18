return {
	"lewis6991/gitsigns.nvim",
	-- Load on file open so hunk signs appear automatically. The hunk/blame
	-- keymaps live in editor/keybinds.lua, per the usual convention.
	event = { "BufReadPre", "BufNewFile" },
	opts = {},
}
