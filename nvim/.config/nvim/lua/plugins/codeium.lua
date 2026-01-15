return {
	"Exafunction/windsurf.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"hrsh7th/nvim-cmp",
	},
	event = "InsertEnter",
	config = function()
		require("codeium").setup({
			enable_chat = true, -- Enable AI chat
		})
	end,
}
