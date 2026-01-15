return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"RRethy/vim-illuminate",
		"hrsh7th/cmp-nvim-lsp",
		{
			"smjonas/inc-rename.nvim",
			config = true,
		},
	},
	config = function()
	-- Suppress deprecation warnings for nvim-lspconfig (Neovim 0.11+)
	-- The old API still works perfectly, just shows warnings about future changes
	-- Will migrate to vim.lsp.config when nvim-lspconfig stabilizes the new API
	local notify = vim.notify
	vim.notify = function(msg, ...)
		if msg and type(msg) == "string" and (msg:match("lspconfig") or msg:match("deprecated")) then
			return
		end
		notify(msg, ...)
	end

	-- import lspconfig plugin
	local lspconfig = require("lspconfig")

	-- import cmp-nvim-lsp plugin
	local cmp_nvim_lsp = require("cmp_nvim_lsp")

		-- enable keybinds only for when lsp server available
		local on_attach = function(client, bufnr)
			require("illuminate").on_attach(client)
		end

		-- used to enable autocompletion (assign to every lsp server config)
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Change the Diagnostic symbols in the sign column (gutter)
		-- (not in youtube nvim video)
		local signs = {
			Error = " ",
			Warn = " ",
			Hint = "󰠠 ",
			Info = " ",
		}
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, {
				text = icon,
				texthl = hl,
				numhl = "",
			})
		end

		-- configure python server
		lspconfig.pyright.setup({
			on_attach = on_attach,
			capabilities = capabilities,
			filetypes = { "python" },
		})

		-- configure python server
		lspconfig.clangd.setup({
			on_attach = on_attach,
			capabilities = capabilities,
			cmd = {
				"clangd",
				"--offset-encoding=utf-16",
			},
		})

	-- configure html server
	lspconfig["html"].setup({
		capabilities = capabilities,
		on_attach = on_attach,
	})

	-- configure typescript/javascript server
	lspconfig["ts_ls"].setup({
		capabilities = capabilities,
		on_attach = on_attach,
		filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
	})

	-- configure css server
		lspconfig["cssls"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- configure tailwindcss server
		lspconfig["tailwindcss"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- configure prisma orm server
		lspconfig["prismals"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
		})

		-- configure graphql language server
		lspconfig["graphql"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
			filetypes = { "graphql", "gql", "typescriptreact", "javascriptreact" },
		})

		-- configure emmet language server
		lspconfig["emmet_ls"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
			filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less" },
		})

		-- configure lua server (with special settings)
		lspconfig["lua_ls"].setup({
			capabilities = capabilities,
			on_attach = on_attach,
			settings = { -- custom settings for lua
				Lua = {
					-- make the language server recognize "vim" global
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						-- make language server aware of runtime files
						library = {
							[vim.fn.expand("$VIMRUNTIME/lua")] = true,
							[vim.fn.stdpath("config") .. "/lua"] = true,
						},
					},
				},
			},
		})

		-- Restore original notify after all LSP setups
		vim.notify = notify
	end,
}
