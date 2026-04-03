-- ============================================================================
-- Custom winbar: editor gets buffer tabs, terminals get terminal tabs
-- ============================================================================

-- Panels: filetype → title shown in winbar with × close button
local panel_titles = {
  ["neo-tree"] = "Files",
  ["Trouble"] = "Diagnostics",
  ["trouble"] = "Diagnostics",
  ["qf"] = "QuickFix",
  ["help"] = "Help",
  ["noice"] = "Notifications",
  ["dapui_scopes"] = "Scopes",
  ["dapui_breakpoints"] = "Breakpoints",
  ["dapui_stacks"] = "Stacks",
  ["dapui_watches"] = "Watches",
  ["dapui_console"] = "Console",
  ["dapui_hover"] = "Hover",
  ["dap-repl"] = "REPL",
  ["git_panel"] = "Source Control",
}

-- DAP UI left-panel filetypes (used for sidebar tab logic)
local dapui_left_fts = {
  dapui_scopes = true, dapui_breakpoints = true,
  dapui_stacks = true, dapui_watches = true,
}

-- Filetypes that get no winbar at all (internal/transient UI)
local excluded_filetypes = {
  ["lazy"] = true, ["mason"] = true,
  ["DressingSelect"] = true, ["DressingInput"] = true,
  ["toggleterm"] = true, ["notify"] = true,
  ["Avante"] = true, ["minifiles"] = true,
  ["ministarter"] = true, ["snacks_terminal"] = true,
  ["dapui_scopes"] = true, ["dapui_breakpoints"] = true,
  ["dapui_stacks"] = true, ["dapui_watches"] = true,
  ["dapui_console"] = true, ["dapui_hover"] = true,
  ["dap-repl"] = true,
  ["git_panel"] = true,
}

local function is_claude(buf)
  return vim.api.nvim_buf_get_name(buf):match("[Cc]laude") ~= nil
end

-- ── Helper: find the non-floating, non-Claude terminal split window ──

local function find_term_split()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local cfg = vim.api.nvim_win_get_config(win)
      local buf = vim.api.nvim_win_get_buf(win)
      if (not cfg.relative or cfg.relative == "")
        and vim.bo[buf].buftype == "terminal"
        and not is_claude(buf) then
        return win
      end
    end
  end
  return nil
end

-- ── Panel close handler (X button on sidebars) ──

function _G.ClosePanel(_minwid, _clicks, button, _mods)
  if button == "l" then
    vim.schedule(function()
      local win = vim.api.nvim_get_current_win()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_hide(win)
      end
    end)
  end
end

-- ── Sidebar tabs: switch left panel between Files and Debug ──

_G.sidebar_tab = "files" -- "files", "git", or "debug"

-- Check if DAP UI left-panel buffers are loaded (debug tab available)
local function dapui_available()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and dapui_left_fts[vim.bo[buf].filetype] then
      return true
    end
  end
  return false
end

-- Build the sidebar tab bar for the winbar
local function build_sidebar_tabs()
  local files_hl = _G.sidebar_tab == "files" and "TabLineSel" or "TabLine"
  local git_hl = _G.sidebar_tab == "git" and "TabLineSel" or "TabLine"
  local tabs = string.format(
    "%%1@v:lua.SidebarTabClick@%%#%s# Files %%X%%#WinBarNC#│%%2@v:lua.SidebarTabClick@%%#%s# Git %%X",
    files_hl, git_hl
  )
  if dapui_available() then
    local debug_hl = _G.sidebar_tab == "debug" and "TabLineSel" or "TabLine"
    tabs = tabs .. string.format(
      "%%#WinBarNC#│%%3@v:lua.SidebarTabClick@%%#%s# Debug %%X",
      debug_hl
    )
  end
  return tabs .. "%#WinBar#"
end

function _G.SidebarTabClick(tab_id, _clicks, button, _mods)
  if button ~= "l" then return end
  vim.schedule(function()
    if tab_id == 1 and _G.sidebar_tab ~= "files" then
      _G.sidebar_show_files()
    elseif tab_id == 2 and _G.sidebar_tab ~= "git" then
      _G.sidebar_show_git()
    elseif tab_id == 3 and _G.sidebar_tab ~= "debug" then
      _G.sidebar_show_debug()
    end
  end)
end

function _G.sidebar_show_files()
  _G.sidebar_tab = "files"
  pcall(function() require("dapui").close() end)
  pcall(function() require("config.git-panel").close() end)
  vim.cmd("Neotree filesystem show")
end

function _G.sidebar_show_git()
  _G.sidebar_tab = "git"
  pcall(function() require("dapui").close() end)
  vim.cmd("Neotree close")
  require("config.git-panel").open()
end

function _G.sidebar_show_debug()
  _G.sidebar_tab = "debug"
  vim.cmd("Neotree close")
  pcall(function() require("config.git-panel").close() end)
  pcall(function() require("dapui").open() end)
end

function _G.toggle_dapui()
  if _G.sidebar_tab == "debug" then
    _G.sidebar_show_files()
  else
    _G.sidebar_show_debug()
  end
end

-- ── Editor buffer tab handlers ──

function _G.BufTabSwitch(bufnr, _clicks, button, _mods)
  if button == "l" and vim.api.nvim_buf_is_valid(bufnr) then
    -- Use getmousepos to target the window whose winbar was clicked,
    -- not the previously focused window (critical for split view)
    local mousepos = vim.fn.getmousepos()
    local win = mousepos and mousepos.winid
    if win and win > 0 and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_buf(win, bufnr)
      vim.api.nvim_set_current_win(win)
    else
      vim.api.nvim_set_current_buf(bufnr)
    end
  end
end

function _G.BufTabClose(bufnr, _clicks, button, _mods)
  if button == "l" then
    -- Focus the window whose winbar was clicked before closing
    local mousepos = vim.fn.getmousepos()
    local win = mousepos and mousepos.winid
    if win and win > 0 and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
    end
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        _G.smart_close_buf(bufnr)
      end
    end)
  end
end

-- ── Terminal tab handlers ──

function _G.TermTabSwitch(bufnr, _clicks, button, _mods)
  if button == "l" and vim.api.nvim_buf_is_valid(bufnr) then
    local win = find_term_split()
    if win then
      vim.api.nvim_win_set_buf(win, bufnr)
      vim.api.nvim_set_current_win(win)
      vim.cmd("stopinsert")
    end
  end
end

function _G.TermTabClose(bufnr, _clicks, button, _mods)
  if button == "l" then
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end)
  end
end

-- ── Terminal toggle: bottom split managed by edgy ──

function _G.toggle_terminal()
  local win = find_term_split()
  if win then
    -- Hide the terminal split (buffers survive thanks to 'hidden')
    vim.api.nvim_win_hide(win)
    return
  end

  -- No visible terminal — find an existing terminal buffer to restore
  local term_buf = nil
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buftype == "terminal"
      and vim.api.nvim_buf_is_loaded(b)
      and not is_claude(b) then
      term_buf = b
      break
    end
  end

  if term_buf then
    -- Restore existing terminal (edgy routes it to bottom panel)
    vim.cmd("botright split")
    vim.cmd("resize " .. math.floor(vim.o.lines * 0.3))
    vim.api.nvim_set_current_buf(term_buf)
  else
    -- First terminal — create it (edgy routes it to bottom panel)
    vim.cmd("botright split | terminal")
    vim.cmd("resize " .. math.floor(vim.o.lines * 0.3))
  end
  vim.cmd("stopinsert")
end

-- ── New terminal creation ──

function _G.new_terminal_tab(_minwid, _clicks, button, _mods)
  if button and button ~= "l" then return end
  vim.schedule(function()
    local win = find_term_split()
    if not win then
      -- No terminal split — create one (edgy routes to bottom panel)
      vim.cmd("botright split | terminal")
      vim.cmd("resize " .. math.floor(vim.o.lines * 0.3))
      return
    end

    -- Suppress autocmds so buffer stays clean for jobstart
    local old_ei = vim.o.eventignore
    vim.o.eventignore = "all"

    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_set_current_win(win)

    vim.o.eventignore = old_ei

    vim.fn.jobstart(vim.o.shell, { term = true })
    vim.cmd("stopinsert")
  end)
end

-- ── Smart split: only split editor windows, never terminals/panels ──

local function find_editor_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local cfg = vim.api.nvim_win_get_config(win)
      local buf = vim.api.nvim_win_get_buf(win)
      if (not cfg.relative or cfg.relative == "")
        and vim.bo[buf].buftype == ""
        and not excluded_filetypes[vim.bo[buf].filetype] then
        return win
      end
    end
  end
  return nil
end

function _G.smart_split(vertical)
  local buf = vim.api.nvim_get_current_buf()
  local bt = vim.bo[buf].buftype
  local ft = vim.bo[buf].filetype

  -- If current window is not an editor, jump to one first
  if bt ~= "" or excluded_filetypes[ft] or panel_titles[ft] then
    local editor_win = find_editor_win()
    if editor_win then
      vim.api.nvim_set_current_win(editor_win)
    else
      vim.notify("No editor window to split", vim.log.levels.WARN)
      return
    end
  end

  if vertical then
    vim.cmd("vsplit")
  else
    vim.cmd("split")
  end
end

-- ── Smart close: collapse split when last buffer in a window is closed ──

local function count_editor_wins()
  local n = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local cfg = vim.api.nvim_win_get_config(win)
      local buf = vim.api.nvim_win_get_buf(win)
      if (not cfg.relative or cfg.relative == "")
        and vim.bo[buf].buftype == ""
        and not excluded_filetypes[vim.bo[buf].filetype]
        and not panel_titles[vim.bo[buf].filetype] then
        n = n + 1
      end
    end
  end
  return n
end

function _G.smart_close_buf(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  local win = vim.api.nvim_get_current_win()
  Snacks.bufdelete(bufnr)

  -- After deleting, check if the window now holds an empty scratch buffer
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(win) then return end
    if count_editor_wins() <= 1 then return end

    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" and not vim.bo[buf].modified and vim.bo[buf].buftype == "" then
      vim.api.nvim_win_close(win, false)
    end
  end)
end

-- ── Build editor buffer tabs (excludes ALL terminal/special buffers) ──

local function build_bufline(win_buf)
  local bufs = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted
      and vim.bo[b].buftype == ""
      and not vim.api.nvim_buf_get_name(b):match("^term://")
      and (vim.api.nvim_buf_get_name(b) ~= "" or vim.bo[b].modified) then
      table.insert(bufs, b)
    end
  end

  if #bufs == 0 then return "" end

  local parts = {}

  for _, buf in ipairs(bufs) do
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
    if name == "" then name = "[No Name]" end

    local modified = vim.bo[buf].modified and " +" or ""
    local is_current = buf == win_buf
    local hl = is_current and "%#TabLineSel#" or "%#TabLine#"

    local name_part = string.format(
      "%%%d@v:lua.BufTabSwitch@%s %s%s %%X",
      buf, hl, name, modified
    )
    local close_part = string.format(
      "%%%d@v:lua.BufTabClose@%s× %%X",
      buf, hl
    )

    table.insert(parts, name_part .. close_part)
  end

  return table.concat(parts, "%#WinBarNC#│") .. "%#WinBar#"
end

-- ── Build terminal tabs (only non-Claude terminal buffers) ──

local function build_termline(win_buf)
  local terms = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buftype == "terminal"
      and vim.api.nvim_buf_is_loaded(b)
      and not is_claude(b) then
      table.insert(terms, b)
    end
  end

  if #terms == 0 then return "" end

  local parts = {}

  for i, buf in ipairs(terms) do
    local is_current = buf == win_buf
    local hl = is_current and "%#TabLineSel#" or "%#TabLine#"

    local bufname = vim.api.nvim_buf_get_name(buf)
    local name = "Terminal " .. i

    -- Extract command name (e.g. "zsh", "bash", "node")
    local cmd = bufname:match("term://.-//(%d+:?)(.+)$")
      or bufname:match("term://.-//(.+)$")
      or bufname:match(":(.+)$")
    if cmd then
      cmd = cmd:match("([^/]+)$") or cmd
      if #cmd > 20 then cmd = cmd:sub(1, 20) .. "…" end
      name = i .. ": " .. cmd
    end

    local name_part = string.format(
      "%%%d@v:lua.TermTabSwitch@%s %s %%X",
      buf, hl, name
    )
    local close_part = string.format(
      "%%%d@v:lua.TermTabClose@%s× %%X",
      buf, hl
    )

    table.insert(parts, name_part .. close_part)
  end

  -- Add a [+] button to create new terminal
  local new_part = "%@v:lua.new_terminal_tab@%#TabLine# + %X"
  table.insert(parts, new_part)

  return table.concat(parts, "%#WinBarNC#│") .. "%#WinBar#"
end

-- ── Refresh winbar for all windows ──

local function refresh_bufline()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if not vim.api.nvim_win_is_valid(win) then goto continue end

    -- Skip floating windows (lazygit, pickers, dropdowns, etc.)
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative and cfg.relative ~= "" then goto continue end

    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    local bt = vim.bo[buf].buftype

    local close_btn = "%=%@v:lua.ClosePanel@%#TabLine# × %X"
    local panel = panel_titles[ft]

    if bt == "terminal" and not is_claude(buf) then
      -- Regular terminal → show terminal tabs
      vim.wo[win].winbar = build_termline(buf)
    elseif bt == "terminal" and is_claude(buf) then
      -- Claude Code sidebar → title + close button
      vim.wo[win].winbar = "%#TabLineSel# Claude Code " .. close_btn
    elseif panel then
      -- Sidebar tabs: always on neo-tree/git_panel, also on top DAP panel
      if ft == "neo-tree" or ft == "git_panel" or (ft == "dapui_scopes" and dapui_available()) then
        vim.wo[win].winbar = build_sidebar_tabs()
      else
        -- Known panel → title + close button
        vim.wo[win].winbar = "%#TabLineSel# " .. panel .. " " .. close_btn
      end
    elseif not excluded_filetypes[ft] and bt == "" then
      vim.wo[win].winbar = build_bufline(buf)
    else
      vim.wo[win].winbar = ""
    end
    ::continue::
  end
end

-- Refresh on buffer/window/terminal changes
vim.api.nvim_create_autocmd(
  { "BufEnter", "BufAdd", "BufDelete", "BufModifiedSet", "WinEnter", "FileType", "TermOpen", "TermClose" },
  { callback = function() vim.schedule(refresh_bufline) end }
)

-- ── Terminal behavior ──

-- Unlist terminals from editor tabs + stay in normal mode for bottom-panel terminals only
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.bo.buflisted = false
    vim.schedule(function()
      local win = vim.api.nvim_get_current_win()
      if not vim.api.nvim_win_is_valid(win) then return end
      local cfg = vim.api.nvim_win_get_config(win)
      -- Only force normal mode for non-floating, non-Claude terminals (bottom panel)
      if (not cfg.relative or cfg.relative == "") and not is_claude(vim.api.nvim_get_current_buf()) then
        vim.cmd("stopinsert")
      end
    end)
  end,
})

-- ============================================================================
-- Custom statuscolumn: VS Code-style gutter with click handlers
-- ============================================================================

-- Left-click sign area → toggle breakpoint; right-click → gutter menu
function _G.SignClick(_, clicks, button, _)
  if button == "l" then
    require("dap").toggle_breakpoint()
  elseif button == "r" then
    vim.schedule(function() vim.cmd("popup GutterPopUp") end)
  end
end

-- Right-click line number → gutter menu
function _G.LineNrClick(_, clicks, button, _)
  if button == "r" then
    vim.schedule(function() vim.cmd("popup GutterPopUp") end)
  end
end

-- Click fold column → toggle fold
function _G.FoldClick(_, clicks, button, _)
  if button == "l" then
    local line = vim.fn.getmousepos().line
    if vim.fn.foldlevel(line) > 0 then
      vim.cmd(line .. "foldtoggle")
    end
  end
end

vim.o.statuscolumn = "%@v:lua.SignClick@%s%T%=%@v:lua.LineNrClick@%l %T%@v:lua.FoldClick@%C%T"

-- Gutter right-click popup menu (breakpoints + git actions)
local gutter_items = {
  { label = "Toggle Breakpoint",    key = "F9",   action = "<cmd>lua require('dap').toggle_breakpoint()<cr>" },
  { label = "Conditional Breakpoint", key = "␣dB", action = "<cmd>lua require('dap').set_breakpoint(vim.fn.input('Condition: '))<cr>" },
  { label = "Log Point",            key = "",     action = "<cmd>lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Log message: '))<cr>" },
  { label = "Run to Cursor",        key = "",     action = "<cmd>lua require('dap').run_to_cursor()<cr>" },
  { label = "---" },
  { label = "Preview Hunk Inline",  key = "",     action = "<cmd>Gitsigns preview_hunk_inline<cr>" },
  { label = "Stage Hunk",           key = "␣ghs", action = "<cmd>Gitsigns stage_hunk<cr>" },
  { label = "Reset Hunk",           key = "␣ghr", action = "<cmd>Gitsigns reset_hunk<cr>" },
  { label = "Undo Stage Hunk",      key = "",     action = "<cmd>Gitsigns undo_stage_hunk<cr>" },
  { label = "---" },
  { label = "Blame Line",           key = "␣gB",  action = "<cmd>Gitsigns blame_line full=true<cr>" },
  { label = "Toggle Inline Blame",  key = "",     action = "<cmd>Gitsigns toggle_current_line_blame<cr>" },
  { label = "Toggle Word Diff",     key = "",     action = "<cmd>Gitsigns toggle_word_diff<cr>" },
}

do
  local max_len = 0
  for _, item in ipairs(gutter_items) do
    if item.label ~= "---" then max_len = math.max(max_len, #item.label) end
  end
  local sep_n = 0
  for _, item in ipairs(gutter_items) do
    if item.label == "---" then
      sep_n = sep_n + 1
      vim.cmd(string.format("anoremenu GutterPopUp.-%d- <Nop>", sep_n))
    else
      local pad = max_len - #item.label + 4
      local name = item.label:gsub(" ", "\\ ") .. string.rep("\\ ", pad) .. item.key:gsub(" ", "\\ ")
      vim.cmd(string.format("anoremenu GutterPopUp.%s %s", name, item.action))
    end
  end
end

-- ============================================================================
-- Right-click context menu
-- ============================================================================

vim.o.mousemodel = "popup_setpos" -- right-click positions cursor + opens menu

-- Clear default popup menu and its autocommand (conflicts with custom items)
pcall(vim.cmd, "aunmenu PopUp")
pcall(vim.cmd, "autocmd! nvim.popupmenu")

local popup_items = {
  { label = "Go to Definition",  key = "F12",    action = "<cmd>lua vim.lsp.buf.definition()<cr>" },
  { label = "Go to References",  key = "S-F12",  action = "<cmd>lua vim.lsp.buf.references()<cr>" },
  { label = "Go to Type",        key = "gt",     action = "<cmd>lua vim.lsp.buf.type_definition()<cr>" },
  { label = "---" },
  { label = "Hover Docs",        key = "K",      action = "<cmd>lua vim.lsp.buf.hover()<cr>" },
  { label = "Code Actions",      key = "␣ca",    action = "<cmd>lua vim.lsp.buf.code_action()<cr>" },
  { label = "Rename Symbol",     key = "F2",     action = "<cmd>lua vim.lsp.buf.rename()<cr>" },
  { label = "Format Document",   key = "␣cf",    action = "<cmd>lua require('conform').format()<cr>" },
  { label = "---" },
  { label = "Preview Hunk",      key = "␣ghp",   action = "<cmd>Gitsigns preview_hunk<cr>" },
  { label = "Stage Hunk",        key = "␣ghs",   action = "<cmd>Gitsigns stage_hunk<cr>" },
  { label = "Reset Hunk",        key = "␣ghr",   action = "<cmd>Gitsigns reset_hunk<cr>" },
  { label = "Blame Line",        key = "␣gB",    action = "<cmd>Gitsigns blame_line full=true<cr>" },
  { label = "Toggle Inline Blame", key = "",    action = "<cmd>Gitsigns toggle_current_line_blame<cr>" },
  { label = "---" },
  { label = "Toggle Breakpoint", key = "F9",    action = "<cmd>lua require('dap').toggle_breakpoint()<cr>" },
  { label = "Conditional Break", key = "␣dB",   action = "<cmd>lua require('dap').set_breakpoint(vim.fn.input('Condition: '))<cr>" },
  { label = "Log Point",         key = "",      action = "<cmd>lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Log message: '))<cr>" },
  { label = "---" },
  { label = "Toggle Comment",    key = "Ctrl-/", action = "<cmd>normal gcc<cr>" },
  { label = "Cut",               key = "Ctrl-X", action = '"+x',   mode = "v" },
  { label = "Copy",              key = "Ctrl-C", action = '"+y',   mode = "v" },
  { label = "Paste",             key = "Ctrl-V", action = '"+gP' },
}

-- Calculate max label width for alignment
local max_len = 0
for _, item in ipairs(popup_items) do
  if item.label ~= "---" then
    max_len = math.max(max_len, #item.label)
  end
end

local sep_n = 0
for _, item in ipairs(popup_items) do
  if item.label == "---" then
    sep_n = sep_n + 1
    vim.cmd(string.format("anoremenu PopUp.-%d- <Nop>", sep_n))
  else
    local pad = max_len - #item.label + 4
    local name = item.label:gsub(" ", "\\ ") .. string.rep("\\ ", pad) .. item.key:gsub(" ", "\\ ")
    local mode = item.mode or "a"
    vim.cmd(string.format("%snoremenu PopUp.%s %s", mode, name, item.action))
  end
end

-- ============================================================================
-- Plugin specs
-- ============================================================================

return {
  -- Lualine: statusline only (winbar handled above)
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "onedark",
      },
    },
  },

  -- mini.starter: add Projects to welcome screen
  {
    "nvim-mini/mini.starter",
    optional = true,
    opts = function(_, opts)
      local items = {
        {
          name = "Projects",
          action = [[lua _G.find_projects()]],
          section = string.rep(" ", 22) .. "Telescope",
        },
      }
      vim.list_extend(opts.items, items)
    end,
  },

  -- Noice: enhanced UI for messages, cmdline, popupmenu
  {
    "folke/noice.nvim",
    opts = {
      cmdline = {
        view = "cmdline", -- bottom command line (not popup)
      },
      presets = {
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
    },
  },
}
