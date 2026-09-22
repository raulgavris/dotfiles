return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 300
	end,
	opts = {
		preset = "modern",
		icons = {
			mappings = true,
		},
		win = {
			border = "rounded",
		},
		spec = {
			{ "<leader>f", group = "Find" },
			{ "<leader>g", group = "Git" },
			{ "<leader>l", group = "LSP" },
			{ "<leader>d", group = "Debug" },
			{ "<leader>t", group = "Test" },
			{ "<leader>b", group = "Buffer" },
			{ "<leader>s", group = "Split" },
			{ "<leader>a", group = "AI (Claude)" },
			{ "<leader>x", group = "Trouble" },
			{ "<leader>r", group = "Refactor" },
			{ "<leader>T", group = "Tailwind" },
			{ "<leader>q", group = "Session" },
			{ "<leader>n", group = "Notifications" },
			{ "<leader>o", group = "Outline" },
			{ "<leader>S", group = "Search/Replace" },
			{ "<leader>h", group = "Hunks (Git)" },
			{ "<leader>gd", group = "Diffview" },
			{ "<leader>gf", group = "File history" },
			{ "<leader>ro", group = "Organize imports" },
			{ "<leader>w", group = "Workspace" },
			{ "<leader>m", group = "Markdown" },
		},
	},
}
