-- handle remaps and keybinds
-- Mapping descriptions use [bracketed] letters to show the keys pressed,
-- e.g. "[C]ode [R]ename" => <leader>cr. They surface in which-key.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

--
-- Editor / built-in keybinds
--
vim.keymap.set("n", "<leader>ex", vim.cmd.Ex, { desc = "[Ex]plore (netrw file explorer)" })

-- moving selections
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down ([J])" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up ([K])" })

-- half page jumping center cursor
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll half-page [d]own (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll half-page [u]p (centered)" })

-- keep search terms in middle
vim.keymap.set("n", "n", "nzzzv", { desc = "[n] next search match (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "[N] previous search match (centered)" })

-- paste over keeping register same
vim.keymap.set("x", "<leader>p", '"_dp', { desc = "[P]aste over selection (keep register)" })

-- copy to clipboard
vim.keymap.set("n", "<leader>y", '"+y', { desc = "[Y]ank to system clipboard" })
vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "[Y]ank line to system clipboard" })
vim.keymap.set("v", "<leader>y", '"+y', { desc = "[Y]ank to system clipboard" })

-- delete to null register
vim.keymap.set("n", "<leader>d", '"_d', { desc = "[D]elete to null register" })
vim.keymap.set("v", "<leader>d", '"_d', { desc = "[D]elete to null register" })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Focus window left ([h])" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Focus window right ([l])" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Focus window down ([j])" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Focus window up ([k])" })

-- re-indent whole file (Vim indent engine; distinct from <leader>cf formatter)
vim.keymap.set("n", "<leader>ci", "<S-g>vgg=", { desc = "[C]ode [I]ndent (re-indent whole file)" })

-- toggle wrap
vim.keymap.set("n", "<leader>tw", ":set wrap!<enter>", { desc = "[T]oggle [W]rap" })

-- window resizing
vim.keymap.set("n", "<leader>wk", "<C-w>+", { desc = "[W]indow height up ([k])" })
vim.keymap.set("n", "<leader>wj", "<C-w>-", { desc = "[W]indow height down ([j])" })
vim.keymap.set("n", "<leader>wl", "<C-w>>", { desc = "[W]indow width up ([l])" })
vim.keymap.set("n", "<leader>wh", "<C-w><", { desc = "[W]indow width down ([h])" })

-- line appending
vim.keymap.set("n", "J", "mzJ`z", { desc = "[J]oin line below (keep cursor)" })

--
-- Plugin keybinds
--
-- Plugin modules are required lazily inside callbacks so this file can be
-- loaded before the plugins themselves (and so lazy-loading still works:
-- the require fires on first keypress, loading the plugin on demand).
--
-- A few mappings necessarily live with their plugins and are NOT here:
--   * LSP maps (gd, gr, <leader>cr, <leader>ca, <leader>th, ...) are
--     buffer-local, set on LspAttach in plugins/lsp-config.lua
--   * nvim-cmp completion-menu maps (<C-n>, <C-y>, ...) are internal to cmp,
--     in plugins/cmp.lua
--   * toggleterm's open mapping (<leader>tt) is a plugin option, set in
--     plugins/toggleterm.lua

-- telescope
vim.keymap.set("n", "<leader>ff", function()
	require("telescope.builtin").find_files()
end, { desc = "[F]ind [F]iles (Telescope)" })
vim.keymap.set("n", "<leader>fg", function()
	require("telescope.builtin").live_grep()
end, { desc = "[F]ind by [G]rep (live, Telescope)" })
vim.keymap.set("n", "<leader>fG", function()
	require("telescope.builtin").git_files()
end, { desc = "[F]ind [G]it files (Telescope)" })
vim.keymap.set("n", "<leader>fw", function()
	require("telescope.builtin").grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "[F]ind [W]ord (prompt grep)" })
vim.keymap.set("n", "<leader>fd", function()
	require("telescope.builtin").diagnostics()
end, { desc = "[F]ind [D]iagnostics (Telescope)" })
vim.keymap.set("n", "<leader>fb", function()
	require("telescope.builtin").buffers()
end, { desc = "[F]ind [B]uffers (Telescope)" })
vim.keymap.set("n", "<leader>fr", function()
	require("telescope.builtin").resume()
end, { desc = "[F]ind [R]esume (last picker)" })
vim.keymap.set("n", "<leader>fo", function()
	require("telescope.builtin").oldfiles()
end, { desc = "[F]ind [O]ldfiles (recent)" })
vim.keymap.set("n", "<leader>fh", function()
	require("telescope.builtin").help_tags()
end, { desc = "[F]ind [H]elp tags (Telescope)" })
vim.keymap.set("n", "<leader>fk", function()
	require("telescope.builtin").keymaps()
end, { desc = "[F]ind [K]eymaps (Telescope)" })
vim.keymap.set("n", "<leader>/", function()
	require("telescope.builtin").current_buffer_fuzzy_find()
end, { desc = "Fuzzy find in current buffer ([/])" })

-- harpoon
vim.keymap.set("n", "<leader>ha", function()
	require("harpoon"):list():add()
end, { desc = "[H]arpoon [A]dd file" })
vim.keymap.set("n", "<leader>hm", function()
	local harpoon = require("harpoon")
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "[H]arpoon [M]enu (toggle quick menu)" })
vim.keymap.set("n", "<leader>hh", function()
	require("harpoon"):list():select(1)
end, { desc = "[H]arpoon select 1 ([h])" })
vim.keymap.set("n", "<leader>hj", function()
	require("harpoon"):list():select(2)
end, { desc = "[H]arpoon select 2 ([j])" })
vim.keymap.set("n", "<leader>hk", function()
	require("harpoon"):list():select(3)
end, { desc = "[H]arpoon select 3 ([k])" })
vim.keymap.set("n", "<leader>hl", function()
	require("harpoon"):list():select(4)
end, { desc = "[H]arpoon select 4 ([l])" })
-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set("n", "<leader>hp", function()
	require("harpoon"):list():prev()
end, { desc = "[H]arpoon [P]revious" })
vim.keymap.set("n", "<leader>hn", function()
	require("harpoon"):list():next()
end, { desc = "[H]arpoon [N]ext" })

-- neo-tree
vim.keymap.set("n", "<leader>n", "<cmd>Neotree filesystem reveal left<cr>", { desc = "[N]eo-tree reveal filesystem" })

-- conform (format buffer; "" => normal, visual, operator-pending, select)
vim.keymap.set("", "<leader>cf", function()
	require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "[C]ode [F]ormat buffer" })

-- diagnostics (vim.diagnostic works without an attached LSP)
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "[C]ode [D]iagnostic (float)" })
vim.keymap.set("n", "<leader>cq", vim.diagnostic.setloclist, { desc = "[C]ode diagnostics to loclist ([q])" })
-- jump between diagnostics, showing the float and centering the cursor
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
	vim.cmd("normal! zz")
end, { desc = "Previous [d]iagnostic (centered)" })
vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
	vim.cmd("normal! zz")
end, { desc = "Next [d]iagnostic (centered)" })

-- toggleterm: exit terminal-insert mode
vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], { desc = "Terminal: exit insert mode ([Esc])" })

-- undotree (toggle the undo-history panel)
vim.keymap.set("n", "<leader>tu", "<cmd>UndotreeToggle<cr>", { desc = "[T]oggle [U]ndotree" })

-- fugitive (git)
vim.keymap.set("n", "<leader>gs", "<cmd>Git<cr>", { desc = "[G]it [S]tatus (fugitive)" })

print("Loaded keybind settings")
