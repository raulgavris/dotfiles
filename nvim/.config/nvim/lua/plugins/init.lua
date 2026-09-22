return {
	{ "nvim-lua/plenary.nvim", lazy = true }, -- lua functions that many plugins use
	{ "christoomey/vim-tmux-navigator", event = "VeryLazy" }, -- tmux & split window navigation
	{ "inkarkat/vim-ReplaceWithRegister", keys = { { "gr", mode = { "n", "x" } }, "grr" } }, -- replace with register contents using motion (gr + motion)
}
