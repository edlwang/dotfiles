return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	config = function()
		require("nvim-autopairs").setup({})
		print("Loaded autopairs config")
	end,
	-- use opts = {} for passing setup options
	-- this is equalent to setup({}) function
}
