return {
	"nvim-treesitter/nvim-treesitter",
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
		{
			"windwp/nvim-ts-autotag",
			opts = {},
		},
		"JoosepAlviste/nvim-ts-context-commentstring",
		{
			"nvim-treesitter/nvim-treesitter-context",
			opts = {
				enable = true, -- Sticky scroll: shows function context at top of buffer
				max_lines = 3,
				min_window_height = 0,
				line_numbers = true,
				multiline_threshold = 20,
				trim_scope = "outer",
				mode = "cursor",
				separator = nil,
				zindex = 20,
				on_attach = nil,
			},
		},
	},
	build = ":TSUpdate",
	config = function()
		require("ts_context_commentstring").setup({
			enable_autocmd = false,
		})

		local ts = require("nvim-treesitter")

		-- Install core parsers (no-op if already installed)
		ts.install({
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
		})

		-- Bigfile guard
		local function is_bigfile(buf)
			local max_filesize = 100 * 1024 -- 100 KB
			local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
			return ok and stats and stats.size > max_filesize
		end

		-- Auto-install parser + enable highlighting per filetype
		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				if is_bigfile(args.buf) then
					return
				end
				-- Auto-install parser for this filetype
				pcall(ts.install, { args.match })
				-- Enable treesitter highlighting
				pcall(vim.treesitter.start, args.buf)
			end,
		})
	end,
}
