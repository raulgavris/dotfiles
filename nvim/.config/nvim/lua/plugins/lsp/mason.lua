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
				"ts_ls",
				"html",
				"cssls",
				"tailwindcss",
				"pyright",
				"clangd",
				"lua_ls",
				"graphql",
				"emmet_ls",
				"prismals",
			},
			automatic_installation = true,
		})

		mason_null_ls.setup({
			-- list of formatters & linters for mason to install
			ensure_installed = {
				"prettier",
				"stylua",
				"eslint_d",
				"clang-format",
			},
			automatic_installation = true,
		})
	end,
}
