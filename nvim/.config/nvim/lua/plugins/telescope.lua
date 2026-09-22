return {
	"nvim-telescope/telescope.nvim",
	cmd = "Telescope",
	keys = {
		{ "<leader>ff", function() require("core.workspaces").find_files() end, desc = "Find files" },
		{ "<leader>fg", function() require("core.workspaces").live_grep() end, desc = "Live grep" },
		{ "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
		{ "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
		{ "<leader>fc", "<cmd>Telescope grep_string<CR>", desc = "Grep cursor word" },
		{ "<leader>f/", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search in buffer" },
		{ "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "Git status" },
		{ "<leader>gb", "<cmd>Telescope git_branches<CR>", desc = "Git branches" },
		{ "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "Git commits" },
		{ "<leader>gfc", "<cmd>Telescope git_bcommits<CR>", desc = "Git buffer commits" },
		{ "<leader>fp", "<cmd>Telescope project<CR>", desc = "Switch project" },
		{ "<leader>u", "<cmd>Telescope undo<CR>", desc = "Undo tree" },
		{ "<leader>:", "<cmd>Telescope commands<CR>", desc = "All commands" },
		{ "<leader>ch", "<cmd>Telescope command_history<CR>", desc = "Command history" },
		{ "gd", "<cmd>Telescope lsp_definitions<CR>", desc = "LSP definitions" },
		{ "gR", "<cmd>Telescope lsp_references<CR>", desc = "LSP references" },
	},
	dependencies = {
		"nvim-telescope/telescope-project.nvim",
		"debugloop/telescope-undo.nvim",
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		"nvim-telescope/telescope-ui-select.nvim",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local themes = require("telescope.themes")
		local previewers = require("telescope.previewers")

		local new_maker = function(filepath, bufnr, opts)
			opts = opts or {}

			filepath = vim.fn.expand(filepath)
			vim.uv.fs_stat(filepath, function(_, stat)
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

		telescope.setup({
			defaults = {
				file_ignore_patterns = { "node_modules", ".git" },
				follow = true, -- follow symlinks (needed for workspace symlink dirs)
				buffer_previewer_maker = new_maker,
				path_display = { "truncate" },
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous,
						["<C-j>"] = actions.move_selection_next,
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
					},
				},
			},
			extensions = {
				["ui-select"] = { themes.get_dropdown({}) },
				project = {
					base_dirs = {
						{ path = "/Users/raulgavris/Projects", max_depth = 2 },
					},
					hidden_files = true,
					theme = "dropdown",
					order_by = "recent",
					search_by = "title",
					on_project_selected = function(prompt_bufnr)
						local project_actions = require("telescope._extensions.project.actions")
						project_actions.change_working_directory(prompt_bufnr, false)
						-- Close all buffers from previous project, then restore session
						vim.cmd("%bdelete!")
						local ok, persistence = pcall(require, "persistence")
						if ok then
							persistence.load()
						end
						vim.cmd("Neotree reveal")
					end,
				},
			},
		})

		-- Load extensions lazily
		telescope.load_extension("fzf")
		telescope.load_extension("ui-select")
		telescope.load_extension("project")
		telescope.load_extension("undo")
	end,
}
