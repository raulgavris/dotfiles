return {
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = {},
	},
	{
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "williamboman/mason.nvim" },
		opts = {
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
		},
	},
	{
		"jay-babu/mason-null-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"nvimtools/none-ls.nvim",
		},
		opts = {
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
		},
	},
}
