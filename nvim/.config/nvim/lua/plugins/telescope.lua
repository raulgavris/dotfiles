return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-telescope/telescope-file-browser.nvim",
		"nvim-telescope/telescope-project.nvim",
		"debugloop/telescope-undo.nvim",
		"jvgrootveld/telescope-zoxide",
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
		local previewers = require("telescope.previewers")

		local new_maker = function(filepath, bufnr, opts)
			opts = opts or {}

			filepath = vim.fn.expand(filepath)
			vim.loop.fs_stat(filepath, function(_, stat)
				if not stat then
					return
				end
				if stat.size > 100000 then
					return
				else
					previewers.buffer_previewer_maker(filepath, bufnr, opts)
				end
			end)
		end
		-- configure telescope
		telescope.setup({
			file_ignore_patterns = { "node_modules", ".git" },
			-- configure custom mappings
			defaults = {
				buffer_previewer_maker = new_maker,
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
						"/Users/raulgavris/Projects/pws-devs/karma-frontend",
						"/Users/raulgavris/Projects/pws-devs/karma-backend",
						"/Users/raulgavris/Projects/pws-devs/tokenexchange-frontend",
						"/Users/raulgavris/Projects/pws-devs/tokenexchange-admin",
						"/Users/raulgavris/Projects/pws-devs/houdiniswap-backend",
						"/Users/raulgavris/Projects/personal/dotfiles/nvim/.config/nvim",
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
		telescope.load_extension("undo")
		telescope.load_extension("noice")
		telescope.load_extension("zoxide")
	end,
}
