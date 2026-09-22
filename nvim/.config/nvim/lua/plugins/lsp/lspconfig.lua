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

		-- Enable inlay hints globally (parameter names, inferred types)
		vim.lsp.inlay_hint.enable(true)

		-- Enable code lens globally. vim.lsp.codelens.enable handles auto-refresh
		-- on its own, so no BufEnter/InsertLeave autocmd is needed.
		-- (Neovim 0.12 deprecated vim.lsp.codelens.refresh() in favor of enable().)
		vim.lsp.codelens.enable(true)

		-- Global config for all LSP servers
		vim.lsp.config("*", {
			capabilities = cmp_nvim_lsp.default_capabilities(),
			on_attach = function(client, bufnr)
				require("illuminate").on_attach(client)
				-- Signature help: show parameter info when typing function args (Ctrl+s in insert mode)
				if client:supports_method("textDocument/signatureHelp") then
					vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature help" })
				end
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

		-- Explicitly disable ts_ls - using typescript-tools.nvim instead
		vim.lsp.config("ts_ls", {
			filetypes = {}, -- Disable completely
			root_markers = {},
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

		-- ESLint for React/Node projects.
		-- Only attach when an ESLint config exists AND the eslint library is
		-- actually installed in node_modules — otherwise the server errors with
		-- "Unable to find ESLint library" in Biome-only projects or projects
		-- with a stale eslint.config.js left over from a Biome migration.
		vim.lsp.config("eslint", {
			filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
			root_dir = function(bufnr, on_dir)
				local fname = vim.api.nvim_buf_get_name(bufnr)
				local config_root = vim.fs.root(fname, {
					".eslintrc",
					".eslintrc.js",
					".eslintrc.cjs",
					".eslintrc.yaml",
					".eslintrc.yml",
					".eslintrc.json",
					"eslint.config.js",
					"eslint.config.mjs",
					"eslint.config.cjs",
					"eslint.config.ts",
					"eslint.config.mts",
					"eslint.config.cts",
				})
				if not config_root then
					return
				end
				-- Walk up from config_root to find node_modules/eslint (handles hoisted monorepos).
				local lib = vim.fs.find("node_modules/eslint", { path = config_root, upward = true, type = "directory" })[1]
				if not lib then
					return
				end
				on_dir(config_root)
			end,
			settings = {
				workingDirectories = { mode = "auto" },
			},
		})

		-- JSON with schema support (package.json, tsconfig, etc.)
		vim.lsp.config("jsonls", {
			settings = {
				json = {
					schemas = require("schemastore").json.schemas(),
					validate = { enable = true },
				},
			},
		})

		-- YAML with schema support (docker-compose, CI/CD)
		vim.lsp.config("yamlls", {
			settings = {
				yaml = {
					schemas = require("schemastore").yaml.schemas(),
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

		-- Disable ts_ls (using typescript-tools.nvim instead)
		vim.lsp.enable("ts_ls", false)

		-- Enable LSP servers
		vim.lsp.enable({
			-- JavaScript/TypeScript linting
			"eslint",
			-- HTML/CSS
			"html",
			"cssls",
			"tailwindcss",
			"emmet_ls",
			-- Config files
			"jsonls",
			"yamlls",
			-- Lua (for Neovim config)
			"lua_ls",
			-- Docker
			"dockerls",
			"docker_compose_language_service",
			-- GraphQL/Prisma (uncomment if needed)
			-- "graphql",
			-- "prismals",
			-- Python (uncomment if needed)
			-- "pyright",
			-- C/C++ (uncomment if needed)
			-- "clangd",
		})
	end,
}
