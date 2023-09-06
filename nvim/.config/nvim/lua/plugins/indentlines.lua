return {
	"lukas-reineke/indent-blankline.nvim",
	config = function()
		require("indent_blankline").setup({
			space_char_blankline = " ",
			char_highlight_list = {
				"IndentBlanklineIndent1",
			},
		})
	end,
}
