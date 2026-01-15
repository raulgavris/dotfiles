return {
	-- DAP (Debug Adapter Protocol)
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			-- UI for debugger
			{
				"rcarriga/nvim-dap-ui",
				dependencies = { "nvim-neotest/nvim-nio" },
				opts = {
					layouts = {
						{
							elements = {
								{ id = "scopes", size = 0.25 },
								{ id = "breakpoints", size = 0.25 },
								{ id = "stacks", size = 0.25 },
								{ id = "watches", size = 0.25 },
							},
							size = 40,
							position = "left",
						},
						{
							elements = {
								{ id = "repl", size = 0.5 },
								{ id = "console", size = 0.5 },
							},
							size = 10,
							position = "bottom",
						},
					},
				},
			},
			-- Virtual text for debugger
			{ "theHamsta/nvim-dap-virtual-text", opts = {} },
			-- Mason integration for debuggers
			{
				"jay-babu/mason-nvim-dap.nvim",
				dependencies = { "williamboman/mason.nvim" },
				config = function()
					require("mason-nvim-dap").setup({
						ensure_installed = { "js-debug-adapter", "debugpy" },
						automatic_installation = true,
						handlers = {
							function(config)
								require("mason-nvim-dap").default_setup(config)
							end,
						},
					})
				end,
			},
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- Manually configure pwa-node adapter (js-debug-adapter)
			local js_debug_adapter = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"

			dap.adapters["pwa-node"] = {
				type = "server",
				host = "localhost",
				port = "${port}",
				executable = {
					command = "node",
					args = { js_debug_adapter, "${port}" },
				},
			}

			-- Configurations for JavaScript/TypeScript
			local js_config = {
				-- Attach to specific port (default 9229)
				{
					type = "pwa-node",
					request = "attach",
					name = "Attach to Port 9229",
					port = 9229,
					cwd = vim.fn.getcwd(),
					sourceMaps = true,
				},
				-- Attach to running process
				{
					type = "pwa-node",
					request = "attach",
					name = "Attach to Process",
					processId = require("dap.utils").pick_process,
					cwd = vim.fn.getcwd(),
					sourceMaps = true,
				},
				-- Launch current file with node
				{
					type = "pwa-node",
					request = "launch",
					name = "Launch File",
					program = "${file}",
					cwd = vim.fn.getcwd(),
				},
			}

			dap.configurations.javascript = js_config
			dap.configurations.typescript = js_config

			-- Auto-open/close DAP UI
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- Configure DAP signs using the new API (Neovim 0.11+)
			local dap_signs = {
				DapBreakpoint = { text = "●", texthl = "DapBreakpoint" },
				DapBreakpointCondition = { text = "●", texthl = "DapBreakpointCondition" },
				DapBreakpointRejected = { text = "●", texthl = "DapBreakpointRejected" },
				DapStopped = { text = "→", texthl = "DapStopped", linehl = "DapStoppedLine" },
				DapLogPoint = { text = "◆", texthl = "DapLogPoint" },
			}
			for name, sign in pairs(dap_signs) do
				vim.fn.sign_define(name, sign)
			end

			-- Set highlight colors for DAP signs
			vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51400" })
			vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#e5c400" })
			vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#424242" })
			vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379" })
			vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2e4d3d" })
			vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#61afef" })
		end,
	},
}
