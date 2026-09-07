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
          mappings = {
            expand = "<CR>",
            open = { "o", "<2-LeftMouse>" },
            remove = "d",
            edit = "e",
            repl = "r",
            toggle = "t",
          },
          element_mappings = {
            breakpoints = {
              open = { "<CR>", "o", "<2-LeftMouse>" },
            },
            stacks = {
              open = { "<CR>", "o", "<2-LeftMouse>" },
            },
          },
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
        dependencies = { "mason-org/mason.nvim" },
        config = function()
          require("mason-nvim-dap").setup({
            ensure_installed = {
              "js-debug-adapter",
              "debugpy",
              "codelldb",
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
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- Enable TRACE logging for debugging adapter issues
      -- Log: :lua print(vim.fn.stdpath('cache') .. '/dap.log')
      dap.set_log_level("TRACE")

      -- pwa-node adapter (js-debug-adapter)
      -- Uses a function adapter to auto-detect the listen address (IPv4/IPv6)
      -- by parsing the adapter's stdout: "Debug server listening at HOST:PORT"
      local js_debug_adapter = vim.fn.stdpath("data")
        .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"

      -- Adapter state: reuse the same process for parent + child sessions
      local uv = vim.uv or vim.loop
      local adapter_proc = { handle = nil, pid = nil, host = nil, port = nil }

      local function kill_adapter()
        if adapter_proc.pid then
          pcall(uv.kill, adapter_proc.pid, "sigterm")
        end
        adapter_proc = { handle = nil, pid = nil, host = nil, port = nil }
      end

      dap.adapters["pwa-node"] = function(cb, config)
        -- Child sessions (startDebugging) must reuse the existing adapter
        if adapter_proc.host and adapter_proc.port then
          cb({ type = "server", host = adapter_proc.host, port = adapter_proc.port })
          return
        end

        local stdout = uv.new_pipe(false)
        local stderr = uv.new_pipe(false)
        local handle, pid
        local resolved = false

        handle, pid = uv.spawn("node", {
          args = { js_debug_adapter, "0" },
          stdio = { nil, stdout, stderr },
        }, function(code, signal)
          if not resolved then
            vim.schedule(function()
              vim.notify("[DAP] adapter process exited (code=" .. code .. ") before responding", vim.log.levels.ERROR)
            end)
          end
          if stdout and not stdout:is_closing() then stdout:close() end
          if stderr and not stderr:is_closing() then stderr:close() end
          if handle and not handle:is_closing() then handle:close() end
          adapter_proc = { handle = nil, pid = nil, host = nil, port = nil }
        end)

        if not handle then
          vim.notify("[DAP] Failed to spawn node. Is 'node' in PATH?", vim.log.levels.ERROR)
          return
        end

        adapter_proc.handle = handle
        adapter_proc.pid = pid

        stderr:read_start(function(err, chunk)
          if chunk then
            -- Suppress noisy child process errors
            if not chunk:match("Cannot find pending target") then
              vim.schedule(function()
                vim.notify("[DAP] adapter stderr: " .. chunk, vim.log.levels.WARN)
              end)
            end
          end
        end)

        stdout:read_start(function(err, chunk)
          if not chunk then return end
          local host, port = chunk:match("listening at (.+):(%d+)")
          if host and port then
            resolved = true
            adapter_proc.host = host
            adapter_proc.port = tonumber(port)
            stdout:read_stop()
            vim.schedule(function()
              vim.notify("[DAP] adapter listening at " .. host .. ":" .. port, vim.log.levels.INFO)
              cb({
                type = "server",
                host = host,
                port = tonumber(port),
              })
            end)
          end
        end)
      end

      -- Clean up adapter when all debug sessions end
      dap.listeners.before.event_terminated["pwa-node-cleanup"] = kill_adapter
      dap.listeners.before.event_exited["pwa-node-cleanup"] = kill_adapter

      -- Shared attach/launch defaults for JS/TS
      local skip = { "<node_internals>/**" }
      local source_map_overrides = {
        ["webpack:///./~/*"] = "${workspaceFolder}/node_modules/*",
        ["webpack:///./*"] = "${workspaceFolder}/*",
        ["webpack:///*"] = "*",
      }

      -- Detect project root from current buffer (walks up to package.json)
      -- nvim-dap calls functions in configs lazily, so this runs at debug time
      local function project_cwd()
        local buf_path = vim.api.nvim_buf_get_name(0)
        if buf_path ~= "" then
          local root = vim.fs.find({ "package.json", "tsconfig.json" }, {
            path = vim.fs.dirname(buf_path),
            upward = true,
            stop = vim.env.HOME,
          })
          if root[1] then
            return vim.fs.dirname(root[1])
          end
        end
        return vim.fn.getcwd()
      end

      -- JavaScript/TypeScript configurations
      local js_config = {
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach to Port 9229 (ts-node/node --inspect)",
          port = 9229,
          cwd = project_cwd,
          sourceMaps = true,
          pauseForSourceMap = true,
          autoAttachChildProcesses = false,
          attachExistingChildren = false,
          resolveSourceMapLocations = { "**", "!**/node_modules/**" },
          sourceMapPathOverrides = source_map_overrides,
          skipFiles = skip,
        },
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach to Process",
          processId = require("dap.utils").pick_process,
          cwd = project_cwd,
          sourceMaps = true,
          pauseForSourceMap = true,
          autoAttachChildProcesses = false,
          attachExistingChildren = false,
          resolveSourceMapLocations = { "**", "!**/node_modules/**" },
          sourceMapPathOverrides = source_map_overrides,
          skipFiles = skip,
        },
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch with ts-node",
          runtimeExecutable = "ts-node",
          runtimeArgs = { "-T" },
          program = "${file}",
          cwd = project_cwd,
          sourceMaps = true,
          pauseForSourceMap = true,
          sourceMapPathOverrides = source_map_overrides,
          skipFiles = skip,
        },
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch with Node",
          program = "${file}",
          cwd = project_cwd,
          sourceMaps = true,
          skipFiles = skip,
        },
        {
          type = "pwa-node",
          request = "launch",
          name = "Debug Jest Tests",
          runtimeExecutable = "node",
          runtimeArgs = { "./node_modules/jest/bin/jest.js", "--runInBand" },
          rootPath = "${workspaceFolder}",
          cwd = project_cwd,
          console = "integratedTerminal",
          internalConsoleOptions = "neverOpen",
          skipFiles = skip,
        },
        {
          type = "pwa-node",
          request = "launch",
          name = "Debug Current Jest File",
          runtimeExecutable = "node",
          runtimeArgs = { "./node_modules/jest/bin/jest.js", "--runInBand", "${file}" },
          rootPath = "${workspaceFolder}",
          cwd = project_cwd,
          console = "integratedTerminal",
          internalConsoleOptions = "neverOpen",
          skipFiles = skip,
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
        request = "attach",
        name = "Attach to Chrome (port 9222)",
        port = 9222,
        webRoot = vim.fn.getcwd(),
        sourceMaps = true,
        skipFiles = { "<node_internals>/**", "node_modules/**" },
      })

      dap.configurations.typescriptreact = react_config
      dap.configurations.javascriptreact = react_config

      -- ================================================================
      -- Debug toolbar (floating, like VS Code)
      -- ================================================================
      local toolbar_win = nil
      local toolbar_buf = nil
      local toolbar_ns = vim.api.nvim_create_namespace("dap_toolbar")

      -- Nerd Font icons (codicons): nr2char for LuaJIT compat
      local nr = vim.fn.nr2char
      local toolbar_buttons = {
        { icon = " " .. nr(0xeab4) .. " ", action = "continue",   hl = "DapToolbarContinue",   desc = "Continue (F5)" },
        { icon = " " .. nr(0xea9c) .. " ", action = "step_over",  hl = "DapToolbarStep",       desc = "Step Over (F10)" },
        { icon = " " .. nr(0xea9a) .. " ", action = "step_into",  hl = "DapToolbarStep",       desc = "Step Into (F11)" },
        { icon = " " .. nr(0xea9b) .. " ", action = "step_out",   hl = "DapToolbarStep",       desc = "Step Out (S-F11)" },
        { icon = " " .. nr(0xeb50) .. " ", action = "restart",    hl = "DapToolbarRestart",    desc = "Restart" },
        { icon = " " .. nr(0xf04d) .. " ", action = "disconnect", hl = "DapToolbarStop",       desc = "Disconnect" },
      }

      -- Map button index to DAP action
      local function toolbar_action(idx)
        local btn = toolbar_buttons[idx]
        if not btn then return end
        if btn.action == "continue" then dap.continue()
        elseif btn.action == "step_over" then dap.step_over()
        elseif btn.action == "step_into" then dap.step_into()
        elseif btn.action == "step_out" then dap.step_out()
        elseif btn.action == "restart" then dap.restart()
        elseif btn.action == "disconnect" then dap.disconnect({ terminateDebuggee = false })
        end
      end

      local function close_toolbar()
        if toolbar_win and vim.api.nvim_win_is_valid(toolbar_win) then
          pcall(vim.api.nvim_win_close, toolbar_win, true)
        end
        if toolbar_buf and vim.api.nvim_buf_is_valid(toolbar_buf) then
          pcall(vim.api.nvim_buf_delete, toolbar_buf, { force = true })
        end
        toolbar_win = nil
        toolbar_buf = nil
      end

      local function open_toolbar()
        close_toolbar()

        local buf = vim.api.nvim_create_buf(false, true)
        toolbar_buf = buf
        vim.bo[buf].bufhidden = "wipe"

        -- Build display line and track button ranges (display + byte positions)
        local sep = nr(0x2502) -- │
        local parts = {}
        local button_ranges = {} -- { start_dcol, stop_dcol, start_byte, stop_byte, idx }
        local display_col = 0
        local byte_col = 0
        local sep_bytes = #sep
        for i, btn in ipairs(toolbar_buttons) do
          local icon_w = vim.fn.strdisplaywidth(btn.icon)
          local icon_b = #btn.icon
          table.insert(button_ranges, {
            start = display_col, stop = display_col + icon_w,
            sb = byte_col, eb = byte_col + icon_b,
            idx = i,
          })
          display_col = display_col + icon_w
          byte_col = byte_col + icon_b
          parts[i] = btn.icon
          if i < #toolbar_buttons then
            display_col = display_col + 1
            byte_col = byte_col + sep_bytes
          end
        end
        local line = table.concat(parts, sep)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { line })
        vim.bo[buf].modifiable = false

        -- Apply default highlights
        local function apply_default_highlights(hovered_idx)
          vim.api.nvim_buf_clear_namespace(buf, toolbar_ns, 0, -1)
          for i, r in ipairs(button_ranges) do
            local hl = toolbar_buttons[i].hl
            if i == hovered_idx then
              hl = hl .. "Hover"
            end
            vim.api.nvim_buf_add_highlight(buf, toolbar_ns, hl, 0, r.sb, r.eb)
            if i < #toolbar_buttons then
              vim.api.nvim_buf_add_highlight(buf, toolbar_ns, "FloatBorder", 0, r.eb, r.eb + sep_bytes)
            end
          end
        end
        apply_default_highlights(nil)

        local total_display = vim.fn.strdisplaywidth(line)
        local editor_width = vim.o.columns
        local win_col = math.floor((editor_width - total_display - 2) / 2)

        local win = vim.api.nvim_open_win(buf, false, {
          relative = "editor",
          row = 1,
          col = win_col,
          width = total_display,
          height = 1,
          style = "minimal",
          border = "rounded",
          focusable = true,
          zindex = 200,
        })
        toolbar_win = win
        vim.wo[win].cursorline = false
        vim.wo[win].winhighlight = "Normal:DapToolbarBg,FloatBorder:DapToolbarBorder"

        -- Hover: highlight button under cursor
        local last_hover = nil
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
          buffer = buf,
          callback = function()
            if not vim.api.nvim_win_is_valid(win) then return end
            local vcol = vim.fn.virtcol(".")
            local hovered = nil
            for _, r in ipairs(button_ranges) do
              if vcol > r.start and vcol <= r.stop then
                hovered = r.idx
                break
              end
            end
            if hovered ~= last_hover then
              last_hover = hovered
              apply_default_highlights(hovered)
            end
          end,
        })

        -- Mouse click handler: determine which button from cursor position
        local prev_win = vim.fn.win_getid(vim.fn.winnr("#"))
        vim.keymap.set("n", "<LeftRelease>", function()
          local cursor_col = vim.fn.virtcol(".")
          for _, r in ipairs(button_ranges) do
            if cursor_col > r.start and cursor_col <= r.stop then
              if prev_win and vim.api.nvim_win_is_valid(prev_win) then
                vim.api.nvim_set_current_win(prev_win)
              end
              vim.schedule(function() toolbar_action(r.idx) end)
              return
            end
          end
        end, { buffer = buf, nowait = true, silent = true })

        -- Esc returns focus
        vim.keymap.set("n", "<Esc>", function()
          if prev_win and vim.api.nvim_win_is_valid(prev_win) then
            vim.api.nvim_set_current_win(prev_win)
          end
        end, { buffer = buf, nowait = true, silent = true })
      end

      -- Auto-open/close DAP UI + toolbar + sidebar tabs + exception breakpoints
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dap.set_exception_breakpoints({ "uncaught" })
        _G.sidebar_show_debug()
        open_toolbar()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        close_toolbar()
        _G.sidebar_show_files()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        close_toolbar()
        _G.sidebar_show_files()
      end
      dap.listeners.after.disconnect["dapui_config"] = function()
        close_toolbar()
        _G.sidebar_show_files()
      end

      -- Toolbar highlight groups
      -- Toolbar highlights: normal + hover (lighter bg)
      local tb_bg = "#1e1e2e"
      local tb_hover = "#313244"
      vim.api.nvim_set_hl(0, "DapToolbarBg", { bg = tb_bg })
      vim.api.nvim_set_hl(0, "DapToolbarBorder", { fg = "#45475a", bg = tb_bg })
      vim.api.nvim_set_hl(0, "DapToolbarContinue", { fg = "#a6e3a1", bg = tb_bg, bold = true })
      vim.api.nvim_set_hl(0, "DapToolbarStep", { fg = "#89b4fa", bg = tb_bg })
      vim.api.nvim_set_hl(0, "DapToolbarRestart", { fg = "#a6e3a1", bg = tb_bg })
      vim.api.nvim_set_hl(0, "DapToolbarStop", { fg = "#f38ba8", bg = tb_bg })
      -- Hover variants
      vim.api.nvim_set_hl(0, "DapToolbarContinueHover", { fg = "#a6e3a1", bg = tb_hover, bold = true })
      vim.api.nvim_set_hl(0, "DapToolbarStepHover", { fg = "#89b4fa", bg = tb_hover })
      vim.api.nvim_set_hl(0, "DapToolbarRestartHover", { fg = "#a6e3a1", bg = tb_hover })
      vim.api.nvim_set_hl(0, "DapToolbarStopHover", { fg = "#f38ba8", bg = tb_hover })

      -- Breakpoint signs
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "●", texthl = "DapBreakpointRejected" })
      vim.fn.sign_define("DapStopped", { text = "→", texthl = "DapStopped", linehl = "DapStoppedLine" })
      vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint" })

      vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51400" })
      vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#e5c400" })
      vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#424242" })
      vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379" })
      vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2e4d3d" })
      vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#61afef" })

      -- DAP UI window protection is handled by edgy.nvim (see layout.lua).
      -- All dapui filetypes are registered in edgy's left/bottom panels,
      -- so edgy prevents files from opening in them and routes to the editor.
    end,
  },
}
