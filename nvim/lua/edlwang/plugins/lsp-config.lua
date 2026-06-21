return {
	{ -- LSP Configuration & Plugins
		"neovim/nvim-lspconfig",
		-- Defer the whole LSP stack (mason, fidget, cmp_nvim_lsp, …) until a real
		-- file is opened, instead of loading it during startup.
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			-- Installs LSP servers and related tools into Neovim's data dir.
			{ "mason-org/mason.nvim", config = true }, -- NOTE: must load before its dependants
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",

			-- LSP progress notifications.
			{ "j-hui/fidget.nvim", opts = {} },

			-- Lua LS support for editing this Neovim config (runtime + plugin paths,
			-- completion, signatures). Replaces neodev.nvim (EOL on Neovim >= 0.10).
			{ "folke/lazydev.nvim", ft = "lua", opts = {} },
		},
		config = function()
			-- Buffer-local LSP keymaps, set whenever a server attaches to a buffer.
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
					map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
					map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
					-- Jump to the *type* of the symbol under the cursor, not its definition.
					map("gy", require("telescope.builtin").lsp_type_definitions, "[g]oto t[y]pe definition")
					map("<leader>fs", require("telescope.builtin").lsp_document_symbols, "[F]ind document [s]ymbols")
					map(
						"<leader>fS",
						require("telescope.builtin").lsp_dynamic_workspace_symbols,
						"[F]ind workspace [S]ymbols"
					)
					map("<leader>cr", vim.lsp.buf.rename, "[C]ode [R]ename")
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
					map("K", vim.lsp.buf.hover, "Hover documentation ([K])")
					-- Goto *Declaration*, not definition — in C this jumps to the header.
					map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					-- While the cursor rests on a symbol, highlight its other
					-- references; clear them when it moves or the server detaches.
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.server_capabilities.documentHighlightProvider then
						local highlight_augroup =
							vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
							end,
						})
					end

					-- Toggle inlay hints, when the attached server provides them.
					if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
						end, "[T]oggle Inlay [H]ints")
					end
				end,
			})

			-- Advertise the extra capabilities nvim-cmp adds (e.g. snippets). Neovim
			-- merges these onto make_client_capabilities() when a client starts, so
			-- we only need to pass the cmp additions.
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Servers to install and enable. Each value table overrides the
			-- lspconfig defaults; available keys include cmd, filetypes, capabilities
			-- and settings (see `:help lspconfig-all`).
			local servers = {
				pyright = {},
				jsonls = {},
				rust_analyzer = {},
				html = {},
				texlab = {},
				lua_ls = {
					settings = {
						Lua = {
							completion = {
								callSnippet = "Replace",
							},
							-- `vim` is a runtime global here; also silence lua_ls's
							-- noisy missing-fields warnings.
							diagnostics = { disable = { "missing-fields" }, globals = { "vim" } },
						},
					},
				},
			}

			-- Register our config with Neovim's built-in LSP framework. `*` applies to
			-- every server; per-server tables (e.g. lua_ls) override on top of the
			-- lspconfig-shipped defaults. mason-lspconfig's `automatic_enable` (on by
			-- default) then enables each installed server for us — the old `handlers`
			-- option this used to rely on was removed in mason-lspconfig v2.
			vim.lsp.config("*", { capabilities = capabilities })
			for server_name, server in pairs(servers) do
				vim.lsp.config(server_name, server)
			end

			-- mason itself is already set up by its dependency spec above
			-- ({ "mason-org/mason.nvim", config = true }), which lazy runs before
			-- this config, so we don't call require("mason").setup() again here.
			-- Run :Mason to view/install tools manually (press g? for help).

			-- Have Mason install the servers above, plus any extra tools listed here.
			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, {
				"stylua", -- Lua formatter, run by conform
			})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			-- `automatic_enable` (on by default) calls vim.lsp.enable() on every
			-- installed Mason package that maps to an lspconfig name. The mason
			-- registry now maps the `stylua` package to nvim-lspconfig's bundled
			-- `lsp/stylua.lua` (cmd `stylua --lsp`), so opening a Lua file tried to
			-- launch stylua as a language server — but we install stylua as a
			-- *formatter* (run by conform), it has no `--lsp` flag and exits 2.
			-- Exclude it so it stays formatter-only; every other server still
			-- auto-enables.
			require("mason-lspconfig").setup({
				automatic_enable = {
					exclude = { "stylua" },
				},
			})
		end,
	},
}
