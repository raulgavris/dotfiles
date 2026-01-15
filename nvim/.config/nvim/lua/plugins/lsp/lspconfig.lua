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
		-- import cmp-nvim-lsp plugin
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		-- Change the Diagnostic symbols in the sign column (gutter)
		vim.diagnostic.config({
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.HINT] = "󰠠 ",
					[vim.diagnostic.severity.INFO] = " ",
				},
			},
		})

		-- Global config for all LSP servers
		vim.lsp.config("*", {
			capabilities = cmp_nvim_lsp.default_capabilities(),
			on_attach = function(client, bufnr)
				require("illuminate").on_attach(client)
			end,
		})

		-- Server-specific configurations
		vim.lsp.config("pyright", {
			filetypes = { "python" },
		})

		vim.lsp.config("clangd", {
			cmd = {
				"clangd",
				"--offset-encoding=utf-16",
			},
		})

		vim.lsp.config("ts_ls", {
			filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
		})

		vim.lsp.config("graphql", {
			filetypes = { "graphql", "gql", "typescriptreact", "javascriptreact" },
		})

		vim.lsp.config("emmet_ls", {
			filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less" },
		})

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						library = {
							[vim.fn.expand("$VIMRUNTIME/lua")] = true,
							[vim.fn.stdpath("config") .. "/lua"] = true,
						},
					},
				},
			},
		})

		-- Enable all LSP servers
		vim.lsp.enable({
			"pyright",
			"clangd",
			"html",
			"ts_ls",
			"cssls",
			"tailwindcss",
			"prismals",
			"graphql",
			"emmet_ls",
			"lua_ls",
		})
	end,
}
