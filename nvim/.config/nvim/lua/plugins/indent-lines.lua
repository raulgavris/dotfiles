return {
	-- Add indentation guides even on blank lines
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		indent = {
			char = "┊",
		},
		scope = {
			enabled = true,
			show_start = true,
			show_end = false,
		},
	},
}
