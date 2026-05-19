require("kaidame.editor")
require("kaidame.lazy")
vim.api.nvim_create_autocmd("VimEnter", {
	command = ":Neotree",
})
print("Loaded kaidame settings")
