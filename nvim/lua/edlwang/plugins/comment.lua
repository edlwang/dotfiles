return {
	"numToStr/Comment.nvim",
	opts = {},
	config = function()
		require("Comment").setup()
		print("Loaded comment.nvim config")
	end,
}
