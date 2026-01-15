return {
	"sindrets/diffview.nvim",
	dependencies = "nvim-lua/plenary.nvim",
	cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
	opts = {
		enhanced_diff_hl = true,
		view = {
			default = {
				layout = "diff2_horizontal",
			},
			merge_tool = {
				layout = "diff3_horizontal",
				disable_diagnostics = true,
			},
			file_history = {
				layout = "diff2_horizontal",
			},
		},
		file_panel = {
			listing_style = "tree",
			tree_options = {
				flatten_dirs = true,
				folder_statuses = "only_folded",
			},
			win_config = {
				position = "left",
				width = 35,
			},
		},
		keymaps = {
			view = {
				["<tab>"] = false,
				["<s-tab>"] = false,
				["gf"] = false,
				["<C-w><C-f>"] = false,
				["<C-w>gf"] = false,
			},
			file_panel = {
				["j"] = false,
				["k"] = false,
				["<cr>"] = false,
				["o"] = false,
				["<2-LeftMouse>"] = false,
				["-"] = false,
				["<tab>"] = false,
				["i"] = false,
				["f"] = false,
				["R"] = false,
				["<c-b>"] = false,
				["<c-f>"] = false,
				["[x"] = false,
				["]x"] = false,
			},
			file_history_panel = {
				["g!"] = false,
				["<C-A-d>"] = false,
				["y"] = false,
				["L"] = false,
				["zR"] = false,
				["zM"] = false,
				["j"] = false,
				["k"] = false,
				["<cr>"] = false,
				["o"] = false,
				["<2-LeftMouse>"] = false,
				["<c-b>"] = false,
				["<c-f>"] = false,
			},
			option_panel = {
				["<tab>"] = false,
				["q"] = false,
			},
		},
	},
}
