return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		build = ":MasonUpdate",
		opts = {},
	},
	{
		"williamboman/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				-- JavaScript/TypeScript (typescript-tools.nvim handles TS server)
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
				-- "dockerls",
				-- "docker_compose_language_service",
				-- GraphQL/Prisma
				-- "graphql",
				-- "prismals",
				-- Python (commented out)
				-- "pyright",
				-- C/C++ (commented out)
				-- "clangd",
			},
			automatic_installation = false,
		},
	},
	{
		"jay-babu/mason-null-ls.nvim",
		event = "VeryLazy",
		dependencies = {
			"williamboman/mason.nvim",
			"nvimtools/none-ls.nvim",
		},
		opts = {
			ensure_installed = {
				"prettier",
				"eslint_d",
				-- Lua (for Neovim config)
				"stylua",
				-- Python (commented out)
				-- "black",
				-- "isort",
				-- "ruff",
				-- C/C++ (commented out)
				-- "clang-format",
			},
			automatic_installation = false,
		},
	},
}
