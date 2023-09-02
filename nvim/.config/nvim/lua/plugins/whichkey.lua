return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 300
		local wk = require("which-key")
		wk.register({
			["<leader>c"] = { name = "Comment selection" },
			-- ["<leader>ff"] = { "<cmd>Telescope find_files<cr>", "Find File" },
			-- ["<leader>fr"] = { "<cmd>Telescope oldfiles<cr>", "Open Recent File" },
			-- ["<leader>fn"] = { "<cmd>enew<cr>", "New File" },
		})
	end,
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
	},
}
