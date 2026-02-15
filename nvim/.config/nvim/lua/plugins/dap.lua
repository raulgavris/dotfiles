return {
	-- DAP (Debug Adapter Protocol)
	{
		"mfussenegger/nvim-dap",
		keys = {
			{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
			{ "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Conditional breakpoint" },
			{ "<leader>dc", function() require("dap").continue() end, desc = "Start/Continue" },
			{ "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
			{ "<leader>do", function() require("dap").step_over() end, desc = "Step over" },
			{ "<leader>dO", function() require("dap").step_out() end, desc = "Step out" },
			{ "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
			{ "<leader>dl", function() require("dap").run_last() end, desc = "Run last" },
			{ "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
			{ "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
			{ "<leader>dh", function() require("dap.ui.widgets").hover() end, desc = "Hover variables" },
			{ "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
			{ "<leader>dR", function() require("dap").restart() end, desc = "Restart" },
		},
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
						ensure_installed = {
							"js-debug-adapter", -- JavaScript/TypeScript/React/Node
							"debugpy", -- Python
							"codelldb", -- C/C++/Rust
							"chrome-debug-adapter", -- Chrome/Browser debugging
						},
						automatic_installation = true,
						handlers = {
							function(config)
								require("mason-nvim-dap").default_setup(config)
							end,
						},
					})
				end,
			},
			-- VSCode JS debugger for browser debugging
			{
				"mxsdev/nvim-dap-vscode-js",
				dependencies = { "mfussenegger/nvim-dap" },
				config = function()
					require("dap-vscode-js").setup({
						debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
						adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
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
				{
					type = "pwa-node",
					request = "attach",
					name = "Attach to Port 9229 (ts-node/node --inspect)",
					port = 9229,
					cwd = vim.fn.getcwd(),
					sourceMaps = true,
					resolveSourceMapLocations = {
						"${workspaceFolder}/**",
						"!**/node_modules/**",
					},
					skipFiles = { "<node_internals>/**", "node_modules/**" },
				},
				{
					type = "pwa-node",
					request = "attach",
					name = "Attach to Process",
					processId = require("dap.utils").pick_process,
					cwd = vim.fn.getcwd(),
					sourceMaps = true,
					skipFiles = { "<node_internals>/**", "node_modules/**" },
				},
				{
					type = "pwa-node",
					request = "launch",
					name = "Launch with ts-node",
					runtimeExecutable = "ts-node",
					runtimeArgs = { "-T" },
					program = "${file}",
					cwd = vim.fn.getcwd(),
					sourceMaps = true,
					skipFiles = { "<node_internals>/**", "node_modules/**" },
				},
				{
					type = "pwa-node",
					request = "launch",
					name = "Launch with Node",
					program = "${file}",
					cwd = vim.fn.getcwd(),
					sourceMaps = true,
					skipFiles = { "<node_internals>/**", "node_modules/**" },
				},
				{
					type = "pwa-node",
					request = "launch",
					name = "Debug Jest Tests",
					runtimeExecutable = "node",
					runtimeArgs = {
						"./node_modules/jest/bin/jest.js",
						"--runInBand",
					},
					rootPath = "${workspaceFolder}",
					cwd = vim.fn.getcwd(),
					console = "integratedTerminal",
					internalConsoleOptions = "neverOpen",
					skipFiles = { "<node_internals>/**", "node_modules/**" },
				},
				{
					type = "pwa-node",
					request = "launch",
					name = "Debug Current Jest File",
					runtimeExecutable = "node",
					runtimeArgs = {
						"./node_modules/jest/bin/jest.js",
						"--runInBand",
						"${file}",
					},
					rootPath = "${workspaceFolder}",
					cwd = vim.fn.getcwd(),
					console = "integratedTerminal",
					internalConsoleOptions = "neverOpen",
					skipFiles = { "<node_internals>/**", "node_modules/**" },
				},
			}

			dap.configurations.javascript = js_config
			dap.configurations.typescript = js_config

			-- React/Browser debugging (Chrome)
			local react_config = vim.deepcopy(js_config)

			table.insert(react_config, {
				type = "pwa-chrome",
				request = "launch",
				name = "Launch Chrome (localhost:3000)",
				url = "http://localhost:3000",
				webRoot = vim.fn.getcwd(),
				sourceMaps = true,
				skipFiles = { "<node_internals>/**", "node_modules/**" },
			})
			table.insert(react_config, {
				type = "pwa-chrome",
				request = "launch",
				name = "Launch Chrome (custom URL)",
				url = function()
					return vim.fn.input("URL: ", "http://localhost:3000")
				end,
				webRoot = vim.fn.getcwd(),
				sourceMaps = true,
				skipFiles = { "<node_internals>/**", "node_modules/**" },
			})
			table.insert(react_config, {
				type = "pwa-chrome",
				request = "attach",
				name = "Attach to Chrome (port 9222)",
				port = 9222,
				webRoot = vim.fn.getcwd(),
				sourceMaps = true,
				skipFiles = { "<node_internals>/**", "node_modules/**" },
			})

			dap.configurations.typescriptreact = react_config
			dap.configurations.javascriptreact = react_config

			-- C/C++ adapter (codelldb)
			local codelldb_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb"

			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = codelldb_path,
					args = { "--port", "${port}" },
				},
			}

			local c_config = {
				{
					name = "Launch file",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
				{
					name = "Attach to process",
					type = "codelldb",
					request = "attach",
					pid = require("dap.utils").pick_process,
					cwd = "${workspaceFolder}",
				},
			}

			dap.configurations.c = c_config
			dap.configurations.cpp = c_config

			-- Python adapter (debugpy - auto-configured by mason-nvim-dap)
			dap.configurations.python = {
				{
					type = "python",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					pythonPath = function()
						local venv = os.getenv("VIRTUAL_ENV")
						if venv then
							return venv .. "/bin/python"
						end
						return "/usr/bin/python3"
					end,
				},
				{
					type = "python",
					request = "launch",
					name = "Launch with arguments",
					program = "${file}",
					args = function()
						local args_string = vim.fn.input("Arguments: ")
						return vim.split(args_string, " ")
					end,
					pythonPath = function()
						local venv = os.getenv("VIRTUAL_ENV")
						if venv then
							return venv .. "/bin/python"
						end
						return "/usr/bin/python3"
					end,
				},
				{
					type = "python",
					request = "attach",
					name = "Attach remote",
					connect = function()
						local host = vim.fn.input("Host [127.0.0.1]: ")
						host = host ~= "" and host or "127.0.0.1"
						local port = tonumber(vim.fn.input("Port [5678]: ")) or 5678
						return { host = host, port = port }
					end,
				},
			}

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

			-- Configure DAP signs
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
