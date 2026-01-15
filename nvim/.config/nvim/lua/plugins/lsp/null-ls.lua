return {
	"nvimtools/none-ls.nvim", -- Maintained fork of null-ls
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvimtools/none-ls-extras.nvim", -- Extra sources including eslint
	},
	config = function()
		local null_ls = require("null-ls")
		local null_ls_utils = require("null-ls.utils")

		local formatting = null_ls.builtins.formatting

		null_ls.setup({
			-- add package.json as identifier for root (for typescript monorepos)
			root_dir = null_ls_utils.root_pattern(".null-ls-root", "Makefile", ".git", "package.json"),
			sources = {
				-- Prettier: uses config if exists, otherwise defaults
				formatting.prettier.with({
					filetypes = {
						"javascript",
						"javascriptreact",
						"typescript",
						"typescriptreact",
						"json",
						"jsonc",
						"yaml",
						"markdown",
						"html",
						"css",
						"scss",
						"less",
						"graphql",
						"svelte",
						"vue",
					},
					prefer_local = "node_modules/.bin",
				}),

				-- ESLint for JS/TS/React
				require("none-ls.diagnostics.eslint_d").with({
					condition = function(utils)
						return utils.root_has_file({ ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", "eslint.config.js", "eslint.config.mjs" })
					end,
				}),

				-- Python
				formatting.black.with({
					extra_args = { "--fast" },
				}),
				formatting.isort,

				-- C/C++
				formatting.clang_format,

				-- Lua
				formatting.stylua,
			},
		})
	end,
}
