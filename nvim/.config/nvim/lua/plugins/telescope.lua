return {
	"nvim-telescope/telescope.nvim",
	-- Using master branch for Neovim 0.11+ compatibility
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
						-- PWS workspace
						"/Users/raulgavris/Projects/pws/houdiniswap-backend",
						"/Users/raulgavris/Projects/pws/houdini-swap-web",
						"/Users/raulgavris/Projects/pws/tokenexchange-admin",
						"/Users/raulgavris/Projects/productivityApp",
						"/Users/raulgavris/Projects/dotfiles",
					},
					hidden_files = true,
					theme = "dropdown",
					order_by = "asc",
					search_by = "title",
					on_project_selected = function(prompt_bufnr)
						-- Switch to project and open Neo-tree
						local project_actions = require("telescope._extensions.project.actions")
						project_actions.change_working_directory(prompt_bufnr, false)
						vim.cmd("Neotree reveal")
					end,
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
