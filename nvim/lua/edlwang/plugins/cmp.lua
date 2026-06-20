return {
	{ -- Autocompletion
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			-- Snippet engine and its nvim-cmp source
			{
				"L3MON4D3/LuaSnip",
				build = (function()
					-- install_jsregexp gives snippets regex support, but needs
					-- `make` and isn't supported on most Windows setups; skip it there.
					if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
						return
					end
					return "make install_jsregexp"
				end)(),
				dependencies = {
					-- A library of premade snippets across many languages.
					{
						"rafamadriz/friendly-snippets",
						config = function()
							require("luasnip.loaders.from_vscode").lazy_load()
						end,
					},
				},
			},
			"saadparwaiz1/cmp_luasnip",

			-- Completion sources; nvim-cmp ships none of these in core.
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			luasnip.config.setup({})

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				completion = { completeopt = "menu,menuone,noinsert" },

				-- Completion-menu maps; kept here (not editor/keybinds.lua) since
				-- they're internal to cmp and only fire while the menu is open.
				mapping = cmp.mapping.preset.insert({
					-- Select the [n]ext / [p]revious item
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-p>"] = cmp.mapping.select_prev_item(),

					-- Scroll the documentation window [b]ack / [f]orward
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),

					-- Accept ([y]es) the completion; auto-imports and expands
					-- snippets when the LSP provides them.
					["<C-y>"] = cmp.mapping.confirm({ select = true }),

					-- Manually trigger completion (rarely needed; cmp opens on its own).
					["<C-Space>"] = cmp.mapping.complete({}),

					-- Jump forward / back through snippet expansion stops.
					["<C-l>"] = cmp.mapping(function()
						if luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						end
					end, { "i", "s" }),
					["<C-h>"] = cmp.mapping(function()
						if luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						end
					end, { "i", "s" }),
				}),
				sources = {
					-- group_index = 0 lets lazydev supply Lua `require` paths ahead of the LSP
					{ name = "lazydev", group_index = 0 },
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
				},
			})
		end,
	},
}
