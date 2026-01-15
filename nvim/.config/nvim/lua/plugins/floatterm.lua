return {
	"numToStr/FTerm.nvim",
	keys = {
		{ "<A-t>", function() require("FTerm").toggle() end, desc = "Toggle terminal" },
	},
	opts = {
		border = "double",
		dimensions = {
			height = 0.9,
			width = 0.9,
		},
	},
}
