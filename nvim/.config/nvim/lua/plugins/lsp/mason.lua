return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"jay-babu/mason-null-ls.nvim", -- Updated to maintained version
	},
	config = function()
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_null_ls = require("mason-null-ls")

		-- enable mason
		mason.setup()

		mason_lspconfig.setup({
			-- list of servers for mason to install
			ensure_installed = {
				-- JavaScript/TypeScript/React/Node
				"ts_ls",
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
			},
			automatic_installation = true,
		})

		mason_null_ls.setup({
			-- list of formatters & linters for mason to install
			ensure_installed = {
				-- JavaScript/TypeScript
				"prettier",
				"eslint_d",
				-- Python
				"black",
				"isort",
				"ruff",
				-- Lua
				"stylua",
				-- C/C++
				"clang-format",
			},
			automatic_installation = true,
		})
	end,
}
