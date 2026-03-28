return {
  -- Neo-tree: file tree sidebar
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      open_files_do_not_replace_types = {
        "terminal", "Trouble", "trouble", "qf", "edgy", "git_panel",
        "dapui_scopes", "dapui_breakpoints", "dapui_stacks",
        "dapui_watches", "dapui_console", "dapui_hover", "dap-repl",
      },
      window = {
        position = "left",
        width = 35,
      },
      filesystem = {
        follow_current_file = { enabled = true },
        filtered_items = {
          visible = false,
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_by_name = {
            "node_modules",
            ".git",
          },
        },
      },
      git_status = {
        window = {
          mappings = {
            ["s"] = "git_add_file",
            ["S"] = "git_add_all",
            ["u"] = "git_unstage_file",
            ["d"] = "git_revert_file",
            ["c"] = "git_commit",
            ["p"] = "git_push",
          },
        },
      },
      default_component_configs = {
        git_status = {
          symbols = {
            added = "+",
            modified = "~",
            deleted = "x",
            renamed = "r",
            untracked = "?",
            ignored = "!",
            unstaged = "u",
            staged = "s",
            conflict = "c",
          },
        },
      },
    },
  },

  -- which-key: keybinding hints
  {
    "folke/which-key.nvim",
    opts = {
      preset = "modern",
      delay = 300,
      win = {
        border = "rounded",
      },
      spec = {
        { "<leader>f", group = "File/Find" },
        { "<leader>c", group = "Code" },
        { "<leader>g", group = "Git" },
        { "<leader>s", group = "Search" },
        { "<leader>d", group = "Debug" },
        { "<leader>x", group = "Diagnostics" },
        { "<leader>a", group = "AI (Claude)" },
        { "<leader>t", group = "Test" },
        { "<leader>o", group = "Organize" },
        { "<leader>w", group = "Workspace" },
        { "<leader>q", group = "Session" },
        { "<leader>n", group = "Notifications" },
      },
    },
  },

  -- vim-tmux-navigator: seamless navigation between nvim splits and tmux panes
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate left (tmux-aware)" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate down (tmux-aware)" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate up (tmux-aware)" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate right (tmux-aware)" },
    },
  },

  -- Claude Code integration
  {
    "coder/claudecode.nvim",
    lazy = false,
    opts = {},
  },

  -- gitsigns: inline blame + git hunk signs
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 500,
      },
      current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
    },
  },

  -- codediff: VS Code-style side-by-side diff with character-level highlighting
  {
    "esmuellert/codediff.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = { "CodeDiff", "CodeDiffClose" },
    keys = {
      { "<leader>gD", "<cmd>CodeDiff<cr>", desc = "Side-by-side diff" },
    },
    config = function()
      require("codediff").setup()
    end,
  },

  -- grug-far: project-wide search and replace (ripgrep for both search + replace)
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    keys = {
      { "<leader>sR", function() require("grug-far").open() end, desc = "Search and replace (grug-far)" },
    },
    opts = {},
  },


  -- snacks.nvim: enable image viewer
  -- iTerm2/WezTerm support Kitty protocol but aren't auto-detected and misposition
  -- images by ~3 rows (tabline/winbar offset). Monkey-patch fixes positioning.
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        force = true,
      },
      picker = {
        sources = {
          files = { follow = true },
          grep = { follow = true },
          grep_word = { follow = true },
        },
      },
    },
  },

  -- vim-visual-multi: VS Code-style multi-cursor editing
  {
    "mg979/vim-visual-multi",
    event = "VeryLazy",
    init = function()
      vim.g.VM_mouse_mappings = 1
      -- Ctrl+D to add next occurrence (VS Code style)
      vim.g.VM_maps = {
        ["Find Under"] = "<C-d>",
        ["Find Subword Under"] = "<C-d>",
      }
    end,
  },
}
