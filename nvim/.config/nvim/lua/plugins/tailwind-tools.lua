return {
	"luckasRanaworthy/tailwind-tools.nvim",
	name = "tailwind-tools",
	build = ":UpdateRemotePlugins",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-telescope/telescope.nvim",
		"neovim/nvim-lspconfig",
	},
	ft = { "html", "javascriptreact", "typescriptreact", "vue", "svelte", "astro" },
	opts = {
		server = {
			override = true, -- Override tailwindcss LSP settings
			settings = {},
		},
		document_color = {
			enabled = true,
			kind = "inline", -- "inline" | "foreground" | "background"
			inline_symbol = "󰝤 ", -- Symbol shown for inline color
			debounce = 200,
		},
		conceal = {
			enabled = false, -- Can enable to hide long class lists
			min_length = nil,
			symbol = "󱏿",
			highlight = {
				fg = "#38BDF8", -- Tailwind sky-400
			},
		},
		cmp = {
			highlight = "foreground", -- Color preview in completion menu
		},
		telescope = {
			utilities = {
				callback = function(name, class)
					-- Insert class at cursor position
					vim.api.nvim_put({ class }, "", true, true)
				end,
			},
		},
		extension = {
			queries = {},
			patterns = {
				-- Add custom patterns for class detection
				javascript = { "clsx%(([^)]+)%)" },
				typescript = { "clsx%(([^)]+)%)" },
				typescriptreact = { "clsx%(([^)]+)%)", "cn%(([^)]+)%)", "cva%(([^)]+)%)" },
				javascriptreact = { "clsx%(([^)]+)%)", "cn%(([^)]+)%)", "cva%(([^)]+)%)" },
			},
		},
	},
	keys = {
		{ "<leader>Tc", "<cmd>TailwindConcealToggle<cr>", desc = "Toggle Tailwind Conceal" },
		{ "<leader>Ti", "<cmd>TailwindColorToggle<cr>", desc = "Toggle Tailwind Colors" },
		{ "<leader>Ts", "<cmd>TailwindSort<cr>", desc = "Sort Tailwind Classes" },
		{ "<leader>Tu", "<cmd>Telescope tailwind utilities<cr>", desc = "Tailwind Utilities" },
	},
}
