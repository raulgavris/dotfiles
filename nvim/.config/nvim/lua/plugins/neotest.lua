return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
		-- Test adapters
		"nvim-neotest/neotest-jest",
		"marilari88/neotest-vitest",
		"nvim-neotest/neotest-python",
	},
	keys = {
		{ "<leader>tt", function() require("neotest").run.run() end, desc = "Run Nearest Test" },
		{ "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File Tests" },
		{ "<leader>ta", function() require("neotest").run.run({ suite = true }) end, desc = "Run All Tests" },
		{ "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run Last Test" },
		{ "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary" },
		{ "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output" },
		{ "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel" },
		{ "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop Tests" },
		{ "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle Watch" },
		{ "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug Nearest Test" },
	},
	config = function()
		require("neotest").setup({
			adapters = {
				-- Jest for React/Next.js/Node
				require("neotest-jest")({
					jestCommand = "npm test --",
					jestConfigFile = function(file)
						if string.find(file, "/packages/") then
							return string.match(file, "(.-/[^/]+/)src") .. "jest.config.ts"
						end
						return vim.fn.getcwd() .. "/jest.config.ts"
					end,
					env = { CI = true },
					cwd = function(file)
						if string.find(file, "/packages/") then
							return string.match(file, "(.-/[^/]+/)src")
						end
						return vim.fn.getcwd()
					end,
				}),
				-- Vitest for modern React/Vue projects
				require("neotest-vitest"),
				-- Python with pytest
				require("neotest-python")({
					dap = { justMyCode = false },
					runner = "pytest",
					python = function()
						local venv = os.getenv("VIRTUAL_ENV")
						if venv then
							return venv .. "/bin/python"
						end
						return "/usr/bin/python3"
					end,
				}),
			},
			status = {
				virtual_text = true,
			},
			output = {
				open_on_run = false,
			},
			quickfix = {
				open = function()
					vim.cmd("Trouble quickfix")
				end,
			},
			icons = {
				passed = "✓",
				failed = "✗",
				running = "⟳",
				skipped = "○",
				unknown = "?",
			},
		})
	end,
}
