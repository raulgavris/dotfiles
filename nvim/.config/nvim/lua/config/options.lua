-- Options are automatically loaded before lazy.nvim startup
-- LazyVim default options: https://www.lazyvim.org/configuration/general

-- Line numbers: absolute (VS Code style)
vim.opt.relativenumber = false
vim.opt.number = true

-- System clipboard
vim.opt.clipboard = "unnamedplus"

-- Indentation: 2 spaces
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

-- Mouse: enable all modes (resize splits by dragging borders)
vim.opt.mouse = "a"

-- Display
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.conceallevel = 0 -- show all text as-is (no concealing)

-- Format on save
vim.g.autoformat = true

-- Session: persist layout, buffers, folds, window sizes
-- (terminal excluded — Neovim can't restore running processes)
vim.opt.sessionoptions = { "buffers", "curdir", "folds", "globals", "help", "skiprtp", "tabpages", "winsize", "winpos" }

-- Root detection: prefer cwd (respects `nvim /path/to/project`)
-- Default is { "lsp", { ".git", "lua" }, "cwd" } which auto-cds away from your intended dir
vim.g.root_spec = { "cwd" }
