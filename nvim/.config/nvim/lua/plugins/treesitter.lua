return {
	"nvim-treesitter/nvim-treesitter",
	module = true,
	event = { "BufReadPost", "BufNewFile" },
	cmd = {
		"TSInstall",
		"TSInstallInfo",
		"TSUpdate",
		"TSBufEnable",
		"TSBufDisable",
		"TSEnable",
		"TSDisable",
		"TSModuleInfo",
	},
	dependencies = {
		"JoosepAlviste/nvim-ts-context-commentstring",
		"windwp/nvim-ts-autotag",
		{
			"nvim-treesitter/nvim-treesitter-context",
			opts = {
				enable = false, -- Enable this plugin (Can be enabled/disabled later via commands)
				max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
				min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
				line_numbers = true,
				multiline_threshold = 20, -- Maximum number of lines to collapse for a single context line
				trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
				mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
				-- Separator between context and content. Should be a single character string, like '-'.
				-- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
				separator = nil,
				zindex = 20, -- The Z-index of the context window
				on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
			},
		},
	},
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.config").setup({
			ensure_installed = {
				-- Shell
				"bash",
				-- C/C++
				"c",
				"cpp",
				"cmake",
				-- Web (React/Next/HTML/CSS)
				"css",
				"scss",
				"html",
				"javascript",
				"typescript",
				"tsx",
				"graphql",
				"prisma",
				-- Python
				"python",
				-- Docker
				"dockerfile",
				-- Config files
				"json",
				"jsonc",
				"yaml",
				"toml",
				"xml",
				"gitignore",
				"gitcommit",
				"git_rebase",
				-- Documentation
				"markdown",
				"markdown_inline",
				"regex",
				-- Lua/Vim
				"lua",
				"vim",
				"vimdoc",
				-- React Native (Java/Kotlin for Android, Swift for iOS)
				"java",
				"kotlin",
				"swift",
			},
			highlight = {
				enable = true, -- false will disable the whole extension
				disable = "", -- list of language that will be disabled
			},
			autopairs = {
				enable = true,
			},
			-- enable autotagging (w/ nvim-ts-autotag plugin)
			autotag = {
				enable = true,
			},
			indent = {
				enable = true,
				disable = {},
			},
			-- enable nvim-ts-context-commentstring plugin for commenting tsx and jsx
			context_commentstring = {
				enable = true,
				enable_autocmd = false,
			},
			-- auto install above language parsers
			auto_install = true,
		})
	end,
}
