return {
	{
		"echasnovski/mini.nvim",
		version = false,
		event = "VeryLazy",
		config = function()
			-- Better Around/Inside textobjects
			--
			-- Examples:
			--  - va)  - [V]isually select [A]round [)]paren
			--  - yinq - [Y]ank [I]nside [N]ext [']quote
			--  - ci'  - [C]hange [I]nside [']quote
			require("mini.ai").setup({
				n_lines = 500,
			})

			-- Add/delete/replace surroundings (brackets, quotes, etc.)
			--
			-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
			-- - sd'   - [S]urround [D]elete [']quotes
			-- - sr)'  - [S]urround [R]eplace [)] [']
			require("mini.surround").setup()

			-- Simple and easy statusline
			-- Can be replaced with lualine if you prefer
			-- require("mini.statusline").setup({ use_icons = vim.g.have_nerd_font })

			-- ... and there is more!
			--  Check out: https://github.com/echasnovski/mini.nvim

			-- Mini pairs for auto-closing brackets
			require("mini.pairs").setup({
				modes = { insert = true, command = false, terminal = false },
				-- skip autopair when next character is one of these
				skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
				-- skip autopair when the cursor is inside these treesitter nodes
				skip_ts = { "string" },
				-- skip autopair when next character is closing pair
				-- and there are more closing pairs than opening pairs
				skip_unbalanced = true,
				-- better deal with markdown code blocks
				markdown = true,
			})

			-- Mini bufremove for better buffer deletion
			require("mini.bufremove").setup()

			-- Mini indentscope for indent guides
			require("mini.indentscope").setup({
				symbol = "│",
				options = { try_as_border = true },
				draw = {
					delay = 100,
					animation = require("mini.indentscope").gen_animation.none(),
				},
			})

			-- Animate cursor movements
			require("mini.animate").setup({
				cursor = {
					enable = true,
					timing = require("mini.animate").gen_timing.linear({ duration = 50, unit = "total" }),
				},
				scroll = {
					enable = false, -- Can be annoying with large files
				},
				resize = {
					enable = false,
				},
				open = {
					enable = false,
				},
				close = {
					enable = false,
				},
			})
		end,
	},
}
