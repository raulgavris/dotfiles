-- VS Code-style layout using edgy.nvim
--
-- ┌──────────┬───────────────────────┬──────────┐
-- │          │  Editor               │  Claude  │
-- │ Neo-tree │                       │  Code    │
-- │          ├───────────────────────┤          │
-- │          │  Terminal / Console   │          │
-- └──────────┴───────────────────────┴──────────┘

local function is_claude(buf)
  return vim.api.nvim_buf_get_name(buf):match("[Cc]laude") ~= nil
end


return {
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    opts = {
      animate = { enabled = false },
      -- Allow mouse drag resize on sidebars (default is winfixwidth=true which blocks it)
      wo = {
        winfixwidth = false,
        winfixheight = false,
      },

      -- Bottom panel: terminals, quickfix, diagnostics, logs, notifications
      -- Only route native vim terminals to bottom (our toggle_terminal uses these).
      -- snacks_terminal is used by Snacks floating tools (lazygit, git log, etc.)
      -- and should NOT be caught here — they stay as popups.
      bottom = {
        {
          ft = "terminal",
          title = "Terminal",
          size = { height = 0.3 },
          filter = function(buf)
            return not is_claude(buf)
          end,
        },
        { ft = "dap-repl", title = "Debug REPL", size = { height = 0.3 } },
        { ft = "dapui_console", title = "Debug Console", size = { height = 0.3 } },
        { ft = "qf", title = "QuickFix" },
        {
          ft = "trouble",
          title = "Diagnostics",
          filter = function(_, win)
            return vim.w[win].trouble
              and vim.w[win].trouble.mode == "diagnostics"
          end,
        },
      },

      -- Left sidebar: file explorer, source control, debug panels
      left = {
        {
          ft = "neo-tree",
          title = "Files",
          size = { width = 35 },
        },
        {
          ft = "git_panel",
          title = "Source Control",
          size = { width = 35 },
        },
        { ft = "dapui_scopes", title = "Scopes", size = { height = 0.25 } },
        { ft = "dapui_breakpoints", title = "Breakpoints", size = { height = 0.25 } },
        { ft = "dapui_stacks", title = "Stacks", size = { height = 0.25 } },
        { ft = "dapui_watches", title = "Watches", size = { height = 0.25 } },
      },

      -- Right sidebar: Claude Code + symbols outline
      right = {
        {
          ft = "terminal",
          title = "Claude Code",
          size = { width = 80 },
          filter = function(buf)
            return is_claude(buf)
          end,
        },
        {
          ft = "snacks_terminal",
          title = "Claude Code",
          size = { width = 80 },
          filter = function(buf)
            return is_claude(buf)
          end,
        },
        {
          ft = "trouble",
          title = "Outline",
          filter = function(_, win)
            return vim.w[win].trouble
              and vim.w[win].trouble.mode == "symbols"
          end,
        },
      },
    },
    keys = {
      -- Toggle panels
      {
        "<leader>ue",
        function()
          require("edgy").toggle()
        end,
        desc = "Toggle edgy panels",
      },
    },
  },
}
