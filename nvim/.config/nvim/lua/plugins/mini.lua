return {
	{
		"echasnovski/mini.nvim",
		version = false,
		event = "VeryLazy",
		config = function()
			-- Better Around/Inside textobjects
			require("mini.ai").setup({
				n_lines = 500,
			})

			-- Add/delete/replace surroundings (brackets, quotes, etc.)
			-- Uses gs prefix to avoid conflict with Flash's s mapping
			require("mini.surround").setup({
				mappings = {
					add = "gsa",
					delete = "gsd",
					find = "gsf",
					find_left = "gsF",
					highlight = "gsh",
					replace = "gsr",
					update_n_lines = "gsn",
				},
			})

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
					enable = false,
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
