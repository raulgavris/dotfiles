-- Autocmds are automatically loaded on the VeryLazy event
-- LazyVim default autocmds: https://www.lazyvim.org/configuration/general

-- Auto-cd into directory argument: `nvim ~/Sites/myproject` sets cwd to that dir
-- This ensures persistence.nvim saves sessions for the right project
vim.api.nvim_create_autocmd("VimEnter", {
  nested = true, -- allow nested autocmds (needed for session restore)
  callback = function()
    local arg = vim.fn.argv(0)
    if arg and arg ~= "" then
      local path = vim.fn.fnamemodify(arg, ":p")
      if vim.fn.isdirectory(path) == 1 then
        vim.cmd("cd " .. vim.fn.fnameescape(path))
        -- Auto-restore session for directory arguments (nvim . / nvim ~/Sites/project)
        -- persistence.nvim skips auto-load when argc > 0, so we trigger it manually.
        -- Use SessionLoadPost for reliable timing after session is fully applied.
        vim.api.nvim_create_autocmd("SessionLoadPost", {
          once = true,
          callback = function()
            vim.schedule(function()
              -- Clean up directory/netrw buffers left over from `nvim .`
              for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(buf) then
                  local name = vim.api.nvim_buf_get_name(buf)
                  if vim.bo[buf].filetype == "netrw"
                    or (name ~= "" and vim.fn.isdirectory(name) == 1 and not vim.bo[buf].modified) then
                    pcall(vim.api.nvim_buf_delete, buf, { force = true })
                  end
                end
              end
              -- Ensure every non-floating editor window shows a real file buffer
              local real_bufs = {}
              for _, b in ipairs(vim.api.nvim_list_bufs()) do
                if vim.bo[b].buflisted and vim.bo[b].buftype == ""
                  and vim.api.nvim_buf_get_name(b) ~= ""
                  and vim.fn.isdirectory(vim.api.nvim_buf_get_name(b)) ~= 1 then
                  table.insert(real_bufs, b)
                end
              end
              if #real_bufs > 0 then
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  if vim.api.nvim_win_is_valid(win) then
                    local cfg = vim.api.nvim_win_get_config(win)
                    if not cfg.relative or cfg.relative == "" then
                      local buf = vim.api.nvim_win_get_buf(win)
                      local name = vim.api.nvim_buf_get_name(buf)
                      if name == "" or vim.fn.isdirectory(name) == 1 then
                        vim.api.nvim_win_set_buf(win, real_bufs[1])
                      end
                    end
                  end
                end
              end
            end)
          end,
        })
        vim.schedule(function()
          local ok, persistence = pcall(require, "persistence")
          if ok then
            persistence.load()
          end
        end)
      else
        -- File argument: cd to its parent directory if it has a .git root
        local dir = vim.fn.fnamemodify(path, ":h")
        local git_root = vim.fs.find(".git", { path = dir, upward = true, type = "directory" })
        if #git_root > 0 then
          vim.cmd("cd " .. vim.fn.fnameescape(vim.fn.fnamemodify(git_root[1], ":h")))
        else
          vim.cmd("cd " .. vim.fn.fnameescape(dir))
        end
      end
    end
  end,
})

-- Go: tabs, 4-wide
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod", "gowork", "gotmpl" },
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- TypeScript/JavaScript/JSON: spaces, 2-wide
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact", "json", "jsonc" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
  end,
})

-- Fix snacks.nvim image positioning in iTerm2/WezTerm.
-- These terminals support Kitty graphics protocol but render images ~3 rows too high
-- because the fallback renderer doesn't account for tabline/winbar offsets.
-- Patches set_cursor on first image open (when all snacks modules are loaded).
vim.api.nvim_create_autocmd("FileType", {
  pattern = "image",
  once = true,
  callback = function()
    local ok, terminal = pcall(require, "snacks.image.terminal")
    if not ok then return end
    local env = terminal.env()
    -- Only patch for non-placeholder terminals (iTerm2, WezTerm)
    -- Kitty/Ghostty use unicode placeholders and position correctly
    if env.placeholders then return end
    local orig_set_cursor = terminal.set_cursor
    terminal.set_cursor = function(pos)
      orig_set_cursor({ pos[1] + 3, pos[2] })
    end
  end,
})

-- Auto-open Neo-tree on startup (edgy no longer pins it, so we open it explicitly).
-- Delayed to let session restore finish first; skips if already visible or in debug mode.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.defer_fn(function()
      if _G.sidebar_tab ~= "files" then return end
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win)
          and vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
          return
        end
      end
      pcall(vim.cmd, "Neotree show")
    end, 300)
  end,
})

-- Uncomment to auto-show menu bar on startup:
-- vim.api.nvim_create_autocmd("VimEnter", {
--   callback = function()
--     vim.defer_fn(function()
--       if _G.toggle_menu_bar then _G.toggle_menu_bar() end
--     end, 100)
--   end,
-- })
