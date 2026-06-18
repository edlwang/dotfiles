-- diagnostic display (pairs with the [d / ]d / <leader>cd maps in keybinds.lua)
vim.diagnostic.config({
	severity_sort = true,
	underline = true,
	float = { border = "rounded", source = "always" },
	virtual_text = { source = "always" },
})
