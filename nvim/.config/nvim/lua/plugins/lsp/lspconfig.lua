return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"RRethy/vim-illuminate",
		"hrsh7th/cmp-nvim-lsp",
		"b0o/schemastore.nvim", -- JSON/YAML schemas
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

		-- ts_ls disabled - using typescript-tools.nvim instead for better performance

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

		-- ESLint for React/Node projects
		vim.lsp.config("eslint", {
			filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
			settings = {
				workingDirectories = { mode = "auto" },
			},
		})

		-- JSON with schema support (package.json, tsconfig, etc.)
		vim.lsp.config("jsonls", {
			settings = {
				json = {
					schemas = require("schemastore").schemas(),
					validate = { enable = true },
				},
			},
		})

		-- YAML with schema support (docker-compose, CI/CD)
		vim.lsp.config("yamlls", {
			settings = {
				yaml = {
					schemas = require("schemastore").schemas(),
					validate = true,
					schemaStore = {
						enable = false,
						url = "",
					},
				},
			},
		})

		-- Docker
		vim.lsp.config("dockerls", {
			filetypes = { "dockerfile" },
		})

		-- Enable all LSP servers
		-- Note: TypeScript handled by typescript-tools.nvim (not ts_ls)
		vim.lsp.enable({
			-- JavaScript/TypeScript linting
			"eslint",
			-- HTML/CSS
			"html",
			"cssls",
			"tailwindcss",
			"emmet_ls",
			-- Python
			"pyright",
			-- C/C++
			"clangd",
			-- Docker
			"dockerls",
			"docker_compose_language_service",
			-- Other
			"lua_ls",
			"graphql",
			"prismals",
			"jsonls",
			"yamlls",
		})
	end,
}
