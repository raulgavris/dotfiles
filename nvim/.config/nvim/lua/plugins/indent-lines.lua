return {
	-- Add indentation guides even on blank lines
	"lukas-reineke/indent-blankline.nvim",
	-- Enable `lukas-reineke/indent-blankline.nvim`
	-- See `:help indent_blankline.txt`
	config = function()
		vim.cmd([[highlight IndentBlanklineChar guifg=#665c54 gui=nocombine]])
		vim.cmd([[highlight IndentBlanklineSpaceChar guifg=#665c54 gui=nocombine]])
		vim.cmd([[highlight IndentBlanklineSpaceCharBlankline  guifg=#665c54 gui=nocombine]])
		vim.cmd([[highlight IndentBlanklineContextChar guifg=#665c54 gui=nocombine]])
		vim.cmd([[highlight IndentBlanklineContextSpaceChar  guifg=#665c54 gui=nocombine]])
		-- vim.cmd([[highlight IndentBlanklineContextStart guifg=#665c54 gui=nocombine]])
		require("indent_blankline").setup({
			show_current_context = true,
			show_current_context_start = true,
			show_trailing_blankline_indent = false,
			char_list = { "┊" },
			use_treesitter = true,
			use_treesitter_scope = true,
		})
	end,
}
