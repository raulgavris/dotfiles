-- Permanent top menu bar rendered in the tabline (topmost position)
-- Always visible. F10/Alt+m/<leader>M or click a category to open dropdowns.
-- Dropdowns support both keyboard (h/j/k/l/Enter/Esc) and mouse (click to execute).

local menu_ns = vim.api.nvim_create_namespace("menu_bar")

-- Currently open dropdown state
local active_cat_idx = nil
local dropdown_win = nil
local dropdown_buf = nil

local categories = {
  {
    name = "File",
    items = {
      { label = "File Explorer", key = "<C-b>", action = "Neotree toggle" },
      { label = "---" },
      { label = "Open Workspace", key = "<leader>ws", action = "WorkspaceSelect" },
      { label = "Add Folder to Workspace", key = "<leader>wa", action = "lua require('config.workspaces').add_folder_interactive()" },
      { label = "Close Workspace", key = "<leader>wc", action = "WorkspaceClose" },
      { label = "---" },
      { label = "Save", key = "<C-s>", action = "w" },
      { label = "Save All", key = "", action = "wa" },
      { label = "---" },
      { label = "Quit", key = "<leader>qq", action = "qa" },
    },
  },
  {
    name = "Edit",
    items = {
      { label = "Undo", key = "<C-z>", action = "undo" },
      { label = "Redo", key = "<C-y>", action = "redo" },
      { label = "---" },
      { label = "Format Document", key = "<leader>cf", action = "lua require('conform').format()" },
      { label = "Code Actions", key = "<leader>ca", action = "lua vim.lsp.buf.code_action()" },
      { label = "Rename Symbol", key = "<F2>", action = "lua vim.lsp.buf.rename()" },
      { label = "---" },
      { label = "Organize Imports", key = "<leader>oi", action = "lua vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })" },
    },
  },
  {
    name = "View",
    items = {
      { label = "Outline", key = "<leader>cs", action = "Trouble symbols toggle focus=false" },
      { label = "---" },
      { label = "Split Down", key = "", action = "lua _G.smart_split(false)" },
      { label = "Split Right", key = "", action = "lua _G.smart_split(true)" },
      { label = "---" },
      { label = "Toggle Word Wrap", key = "", action = "set wrap!" },
      { label = "Toggle Terminal", key = "<C-`>", action = "lua _G.toggle_terminal()" },
      { label = "Notifications", key = "<leader>sn", action = "Noice" },
      { label = "---" },
      { label = "Zen Mode", key = "", action = "lua Snacks.zen()" },
    },
  },
  {
    name = "Search",
    items = {
      { label = "Find Files", key = "<leader>ff", action = "lua require('config.workspaces').find_files()" },
      { label = "Find File", key = "<C-p>", action = "lua Snacks.picker.files()" },
      { label = "Find Project", key = "<leader>fp", action = "lua _G.find_projects()" },
      { label = "Recent Files", key = "<leader>fr", action = "lua Snacks.picker.recent()" },
      { label = "---" },
      { label = "Search in Project", key = "<F4>", action = "lua Snacks.picker.grep()" },
      { label = "Search in File", key = "<C-f>", action = "lua Snacks.picker.lines()" },
      { label = "Search Word", key = "<leader>sw", action = "lua Snacks.picker.grep_word()" },
      { label = "Find and Replace", key = "", action = "lua require('grug-far').open()" },
      { label = "---" },
      { label = "Search Todos", key = "<leader>st", action = "TodoTrouble" },
      { label = "Search Keymaps", key = "<leader>sk", action = "lua Snacks.picker.keymaps()" },
    },
  },
  {
    name = "Code",
    items = {
      { label = "Go to Definition", key = "<F12>", action = "lua Snacks.picker.lsp_definitions()" },
      { label = "Go to References", key = "<S-F12>", action = "lua Snacks.picker.lsp_references()" },
      { label = "Go to Implementation", key = "gi", action = "lua Snacks.picker.lsp_implementations()" },
      { label = "---" },
      { label = "Diagnostics", key = "<leader>xx", action = "Trouble diagnostics toggle" },
      { label = "Buffer Diagnostics", key = "<leader>xX", action = "Trouble diagnostics toggle filter.buf=0" },
    },
  },
  {
    name = "Debug",
    items = {
      { label = "Start / Continue", key = "<F5>", action = "lua require('dap').continue()" },
      { label = "Pause", key = "<leader>dp", action = "lua require('dap').pause()" },
      { label = "Run Last", key = "<leader>dl", action = "lua require('dap').run_last()" },
      { label = "Terminate", key = "<leader>dt", action = "lua require('dap').terminate()" },
      { label = "---" },
      { label = "Attach to Process", key = "<leader>da", action = "lua require('config.dap-attach').attach_process()" },
      { label = "Attach to Port 9229", key = "<leader>dA", action = "lua require('config.dap-attach').attach_port()" },
      { label = "---" },
      { label = "Step Over", key = "<F10>", action = "lua require('dap').step_over()" },
      { label = "Step Into", key = "<F11>", action = "lua require('dap').step_into()" },
      { label = "Step Out", key = "<S-F11>", action = "lua require('dap').step_out()" },
      { label = "---" },
      { label = "Toggle Breakpoint", key = "<F9>", action = "lua require('dap').toggle_breakpoint()" },
      { label = "Conditional Breakpoint", key = "<leader>dB", action = "lua require('dap').set_breakpoint(vim.fn.input('Condition: '))" },
      { label = "Exception Breakpoints", key = "<leader>de", action = "lua vim.ui.select({ 'All Exceptions', 'Uncaught Exceptions', 'None' }, { prompt = 'Break on:' }, function(c) if c == 'All Exceptions' then require('dap').set_exception_breakpoints({ 'caught', 'uncaught' }) elseif c == 'Uncaught Exceptions' then require('dap').set_exception_breakpoints({ 'uncaught' }) elseif c == 'None' then require('dap').set_exception_breakpoints({}) end end)" },
      { label = "---" },
      { label = "Toggle DAP UI", key = "<leader>du", action = "lua _G.toggle_dapui()" },
      { label = "Toggle REPL", key = "<leader>dr", action = "lua require('dap').repl.toggle()" },
      { label = "Hover Variable", key = "<leader>dh", action = "lua require('dap.ui.widgets').hover()" },
    },
  },
  {
    name = "Git",
    items = {
      { label = "Source Control", key = "<leader>gS", action = "lua _G.sidebar_show_git()" },
      { label = "---" },
      { label = "Commit...", key = "", action = "lua require('config.git-panel').commit()" },
      { label = "AI Commit...", key = "", action = "lua require('config.git-panel').commit_generated()" },
      { label = "Commit All...", key = "", action = "lua require('config.git-panel').commit_all()" },
      { label = "Amend", key = "", action = "lua require('config.git-panel').amend()" },
      { label = "---" },
      { label = "Push", key = "", action = "lua require('config.git-panel').push()" },
      { label = "Pull", key = "", action = "lua require('config.git-panel').pull()" },
      { label = "Fetch", key = "", action = "lua require('config.git-panel').fetch()" },
      { label = "---" },
      { label = "Stash", key = "", action = "lua require('config.git-panel').stash()" },
      { label = "Stash Pop", key = "", action = "lua require('config.git-panel').stash_pop()" },
      { label = "---" },
      { label = "AI Merge...", key = "", action = "lua require('config.git-panel').ai_merge()" },
      { label = "---" },
      { label = "LazyGit", key = "<leader>gg", action = "lua Snacks.lazygit()" },
      { label = "Git Status", key = "<leader>gs", action = "lua Snacks.picker.git_status()" },
      { label = "Git Log", key = "<leader>gb", action = "lua Snacks.picker.git_log()" },
      { label = "---" },
      { label = "Blame Line", key = "<leader>gB", action = "lua Snacks.git.blame_line()" },
      { label = "Git Diff", key = "<leader>gd", action = "lua Snacks.picker.git_diff()" },
      { label = "Side-by-Side Diff", key = "<leader>gD", action = "CodeDiff" },
    },
  },
  {
    name = "Terminal",
    items = {
      { label = "Toggle Terminal", key = "<C-`>", action = "lua _G.toggle_terminal()" },
      { label = "New Terminal Tab", key = "", action = "lua _G.new_terminal_tab(nil, nil, 'l', nil)" },
      { label = "---" },
      { label = "Claude: Toggle", key = "<leader>ac", action = "ClaudeCode" },
      { label = "Claude: Focus", key = "<leader>af", action = "ClaudeCodeFocus" },
      { label = "Claude: Resume", key = "<leader>ar", action = "ClaudeCode --resume" },
    },
  },
}

-- ============================================================================
-- Tabline: always-visible menu bar at the topmost position
-- ============================================================================

local function build_tabline(active_idx)
  local parts = {}
  for i, cat in ipairs(categories) do
    local hl = (i == active_idx) and "PmenuSel" or "TabLine"
    -- %N@handler@ makes the text clickable, N is passed as first arg to handler
    parts[i] = string.format("%%%d@v:lua.MenuBarClick@%%#%s# %s %%X", i, hl, cat.name)
  end
  return " " .. table.concat(parts, " ") .. "%#TabLineFill#"
end

local function set_tabline(active_idx)
  vim.o.tabline = build_tabline(active_idx)
end

-- ============================================================================
-- Dropdown helpers
-- ============================================================================

local function first_selectable(items, start, direction)
  local idx = start
  for _ = 1, #items do
    if items[idx] and items[idx].label ~= "---" then return idx end
    idx = idx + (direction or 1)
    if idx > #items then idx = 1 end
    if idx < 1 then idx = #items end
  end
  return nil
end

local function get_category_col(idx)
  local col = 2
  for i = 1, idx - 1 do
    col = col + #categories[i].name + 3
  end
  return col
end

-- ============================================================================
-- Dropdown: focusable floating window with keyboard + mouse support
-- ============================================================================

local function close_dropdown()
  local win = dropdown_win
  local buf = dropdown_buf
  dropdown_win = nil
  dropdown_buf = nil
  active_cat_idx = nil
  set_tabline(nil)

  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

-- Forward declaration
local open_dropdown

open_dropdown = function(cat_idx)
  -- Clean up existing dropdown without resetting tabline
  local old_win = dropdown_win
  local old_buf = dropdown_buf
  dropdown_win = nil
  dropdown_buf = nil

  if old_win and vim.api.nvim_win_is_valid(old_win) then
    pcall(vim.api.nvim_win_close, old_win, true)
  end
  if old_buf and vim.api.nvim_buf_is_valid(old_buf) then
    pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
  end

  active_cat_idx = cat_idx
  set_tabline(cat_idx)

  local cat = categories[cat_idx]
  local items = cat.items

  -- Calculate dimensions
  local max_label, max_key = 0, 0
  for _, item in ipairs(items) do
    if item.label ~= "---" then
      max_label = math.max(max_label, #item.label)
      max_key = math.max(max_key, #(item.key or ""))
    end
  end

  local width = max_label + max_key + 5
  if width < #cat.name + 4 then width = #cat.name + 4 end

  -- Build lines and track separators
  local lines = {}
  local sep_lines = {}

  for i, item in ipairs(items) do
    if item.label == "---" then
      table.insert(lines, " " .. string.rep("─", width - 2) .. " ")
      sep_lines[i] = true
    else
      local key_str = item.key or ""
      local padding = width - #item.label - #key_str - 3
      if padding < 1 then padding = 1 end
      table.insert(lines, " " .. item.label .. string.rep(" ", padding) .. key_str .. " ")
    end
  end

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  -- Highlight separators (non-separator lines use Normal=Pmenu via winhighlight)
  for i in pairs(sep_lines) do
    vim.api.nvim_buf_add_highlight(buf, menu_ns, "Comment", i - 1, 0, -1)
  end

  -- Position below tabline (row 1)
  local col = get_category_col(cat_idx)
  if col + width + 2 > vim.o.columns then
    col = math.max(0, vim.o.columns - width - 2)
  end

  -- Create focusable floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = 1,
    col = col,
    width = width,
    height = #lines,
    style = "minimal",
    border = "rounded",
    focusable = true,
    zindex = 250,
  })

  dropdown_win = win
  dropdown_buf = buf

  -- Styling: cursorline highlights the selected row
  vim.wo[win].cursorline = true
  vim.wo[win].winhighlight = "CursorLine:PmenuSel,Normal:Pmenu,FloatBorder:FloatBorder"
  vim.wo[win].scrolloff = 0

  -- Place cursor on first selectable item
  local first = first_selectable(items, 1, 1) or 1
  vim.api.nvim_win_set_cursor(win, { first, 0 })

  -- ── Local functions ──

  local function navigate(direction)
    local current = vim.fn.line(".")
    local pos = current + direction
    if pos > #items then pos = 1 end
    if pos < 1 then pos = #items end
    local sel = first_selectable(items, pos, direction)
    if sel then
      vim.api.nvim_win_set_cursor(win, { sel, 0 })
    end
  end

  local function execute_current()
    local line = vim.fn.line(".")
    local item = items[line]
    if item and item.label ~= "---" and item.action then
      close_dropdown()
      vim.schedule(function() vim.cmd(item.action) end)
    end
  end

  local function switch_cat(delta)
    local new_idx = cat_idx + delta
    if new_idx < 1 then new_idx = #categories end
    if new_idx > #categories then new_idx = 1 end
    open_dropdown(new_idx)
  end

  -- ── Skip separators on cursor movement (mouse clicks on separator lines) ──

  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      if not vim.api.nvim_win_is_valid(win) then return end
      local line = vim.fn.line(".")
      if sep_lines[line] then
        local next_sel = first_selectable(items, line + 1, 1)
          or first_selectable(items, line - 1, -1)
        if next_sel then
          vim.api.nvim_win_set_cursor(win, { next_sel, 0 })
        end
      end
    end,
  })

  -- ── Close when focus leaves the dropdown (click outside) ──

  local this_win = win
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    callback = function()
      vim.schedule(function()
        -- Only close if this specific dropdown is still the active one
        -- (prevents closing the new dropdown during category switching)
        if dropdown_win == this_win then
          close_dropdown()
        end
      end)
    end,
  })

  -- ── Keymaps (keyboard + mouse) ──

  local kopts = { buffer = buf, nowait = true, silent = true }

  -- Close
  vim.keymap.set("n", "<Esc>", close_dropdown, kopts)
  vim.keymap.set("n", "q", close_dropdown, kopts)

  -- Execute: keyboard
  vim.keymap.set("n", "<CR>", execute_current, kopts)
  vim.keymap.set("n", "<Space>", execute_current, kopts)

  -- Execute: mouse click (ignore the first release from the tabline click that opened us)
  local first_release = true
  vim.keymap.set("n", "<LeftRelease>", function()
    if first_release then
      first_release = false
      return
    end
    execute_current()
  end, kopts)

  -- Navigate within dropdown
  vim.keymap.set("n", "j", function() navigate(1) end, kopts)
  vim.keymap.set("n", "k", function() navigate(-1) end, kopts)
  vim.keymap.set("n", "<Down>", function() navigate(1) end, kopts)
  vim.keymap.set("n", "<Up>", function() navigate(-1) end, kopts)

  -- Switch between categories
  vim.keymap.set("n", "h", function() switch_cat(-1) end, kopts)
  vim.keymap.set("n", "l", function() switch_cat(1) end, kopts)
  vim.keymap.set("n", "<Left>", function() switch_cat(-1) end, kopts)
  vim.keymap.set("n", "<Right>", function() switch_cat(1) end, kopts)
end

-- ============================================================================
-- Global handlers (tabline click + F10 toggle)
-- ============================================================================

-- Called by tabline %@v:lua.MenuBarClick@ when a category is clicked
function _G.MenuBarClick(minwid, _clicks, button, _mods)
  if button == "l" then
    vim.schedule(function()
      if active_cat_idx == minwid then
        close_dropdown() -- toggle off if same category clicked
      else
        open_dropdown(minwid)
      end
    end)
  end
end

-- Called by Ctrl+F10 / Alt+m / <leader>M
function _G.toggle_menu_bar()
  if active_cat_idx then
    close_dropdown()
  else
    open_dropdown(1)
  end
end

-- ============================================================================
-- Initialize
-- ============================================================================

return {
  {
    "LazyVim/LazyVim",
    init = function()
      vim.o.showtabline = 2
      set_tabline(nil)
    end,
  },

  -- Disable bufferline (tabline is used for menu, lualine winbar for buffer tabs)
  {
    "akinsho/bufferline.nvim",
    enabled = false,
  },
}
