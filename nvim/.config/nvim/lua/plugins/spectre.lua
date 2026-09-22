return {
	"MagicDuck/grug-far.nvim",
	cmd = "GrugFar",
	keys = {
		{ "<leader>S", function() require("grug-far").open() end, desc = "Search & Replace (grug-far)" },
		{ "<leader>Sw", function() require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } }) end, desc = "Search current word" },
		{ "<leader>Sf", function() require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } }) end, desc = "Search in current file" },
	},
	opts = {
		headerMaxWidth = 80,
	},
}
