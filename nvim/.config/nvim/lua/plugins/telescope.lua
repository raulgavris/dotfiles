return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-telescope/telescope-file-browser.nvim",
		"nvim-telescope/telescope-project.nvim",
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		"nvim-telescope/telescope-ui-select.nvim",
		"nvim-tree/nvim-web-devicons",
		"ThePrimeagen/harpoon",
	},
	config = function()
		-- import telescope plugin safely
		local telescope = require("telescope")

		-- import telescope actions safely
		local actions = require("telescope.actions")

		-- import telescope-ui-select safely
		local themes = require("telescope.themes")

		-- configure telescope
		telescope.setup({
			-- configure custom mappings
			defaults = {
				path_display = { "truncate" },
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous, -- move to prev result
						["<C-j>"] = actions.move_selection_next, -- move to next result
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist, -- send selected to quickfixlist
					},
				},
			},
			extensions = {
				["ui-select"] = { themes.get_dropdown({}) },
				project = {
					base_dirs = {
						"~/Projects/personal/dotfiles/nvim",
						"~/Projects/pws-devs/karma-frontend",
						"~/Projects/pws-devs/karma-backend",
						"~/Projects/pws-devs/tokenexchange-frontend",
						"~/Projects/pws-devs/tokenexchange-admin",
						"~/Projects/pws-devs/houdiniswap-backend",
					},
					hidden_files = true, -- default: false
					theme = "dropdown",
					order_by = "asc",
					search_by = "title",
					sync_with_nvim_tree = true, -- default false
				},
			},
		})

		telescope.load_extension("fzf")
		telescope.load_extension("ui-select")
		telescope.load_extension("harpoon")
		telescope.load_extension("project")
		telescope.load_extension("file_browser")

		-- set keymaps
		local keymap = vim.keymap -- for conciseness

		keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", {
			desc = "Fuzzy find recent files",
		}) -- find previously opened files
		keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", {
			desc = "Find string under cursor in cwd",
		}) -- find string under cursor in current working directory
		keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", {
			desc = "Show open buffers",
		}) -- list open buffers in current neovim instance
		keymap.set("n", "<leader>hf", "<cmd>Telescope harpoon marks<cr>", {
			desc = "Show harpoon marks",
		}) -- show harpoon marks
		keymap.set("n", "<leader>gc", "<cmd>Telescope git_commits<cr>", {
			desc = "Show git commits",
		}) -- list all git commits (use <cr> to checkout) ["gc" for git commits]
		keymap.set("n", "<leader>gfc", "<cmd>Telescope git_bcommits<cr>", {
			desc = "Show git commits for current buffer",
		}) -- list git commits for current file/buffer (use <cr> to checkout) ["gfc" for git file commits]
	end,
}
