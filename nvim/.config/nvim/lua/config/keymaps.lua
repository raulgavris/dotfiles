-- Keymaps are automatically loaded on the VeryLazy event
-- LazyVim default keymaps: https://www.lazyvim.org/configuration/keymaps

local map = vim.keymap.set
local ws = require("config.workspaces")

-- ============================================================================
-- Find Projects (VS Code "Open Recent" style)
-- ============================================================================

-- Scans persistence.nvim saved sessions to build a project list.
-- Selecting a project: cd's into it, closes all buffers, restores the session
-- (open files, cursor positions, window layout).
local function find_projects()
  local session_dir = vim.fn.stdpath("state") .. "/sessions/"
  local sessions = vim.fn.glob(session_dir .. "*.vim", false, true)

  if #sessions == 0 then
    vim.notify("No saved sessions found. Open a project and quit nvim to create one.", vim.log.levels.INFO)
    return
  end

  -- Decode session filenames back to directory paths
  -- persistence.nvim encodes: / → % and branch separator as %%
  -- e.g. %Users%bogdan%Sites%myproject%%main.vim → /Users/bogdan/Sites/myproject (branch: main)
  local projects = {}
  local seen = {}
  for _, session_file in ipairs(sessions) do
    local name = vim.fn.fnamemodify(session_file, ":t:r") -- strip path + .vim
    -- Strip branch suffix (everything after %% including the %%)
    local dir_part = name:match("^(.-)%%%%") or name
    -- Convert single % back to /
    local dir = dir_part:gsub("%%", "/")
    if vim.fn.isdirectory(dir) == 1 and not seen[dir] then
      seen[dir] = true
      -- Get last modified time for sorting (most recent first)
      local mtime = vim.fn.getftime(session_file)
      table.insert(projects, { dir = dir, mtime = mtime, session = session_file })
    end
  end

  table.sort(projects, function(a, b) return a.mtime > b.mtime end)

  if #projects == 0 then
    vim.notify("No project sessions found for existing directories.", vim.log.levels.INFO)
    return
  end

  local cwd = vim.fn.getcwd()
  local items = {}
  for _, p in ipairs(projects) do
    local label = vim.fn.fnamemodify(p.dir, ":~") -- shorten with ~
    if p.dir == cwd then
      label = label .. " (current)"
    end
    table.insert(items, { name = label, dir = p.dir })
  end

  vim.ui.select(items, {
    prompt = "Switch Project",
    format_item = function(item) return item.name end,
  }, function(choice)
    if not choice then return end
    -- Close everything that holds state from the old project
    vim.cmd("silent! Neotree close")
    vim.cmd("silent! Trouble close")
    vim.cmd("silent! DiffviewClose")
    vim.cmd("silent! cclose")       -- quickfix
    vim.cmd("silent! lclose")       -- loclist

    -- Kill ALL non-editor buffers (terminals, lazygit, dap, etc.)
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[b].buftype ~= "" then
        pcall(vim.api.nvim_buf_delete, b, { force = true })
      end
    end

    -- Close all editor buffers
    vim.cmd("silent! %bdelete!")

    -- Change directory
    vim.cmd("cd " .. vim.fn.fnameescape(choice.dir))
    vim.env.GIT_WORK_TREE = choice.dir -- lazygit picks this up

    -- Load session via persistence.nvim
    local ok, persistence = pcall(require, "persistence")
    if ok then
      persistence.load()
    end

    -- Re-cd after session load (persistence may override cwd)
    vim.cmd("cd " .. vim.fn.fnameescape(choice.dir))
    vim.notify("Switched to: " .. choice.name, vim.log.levels.INFO)
  end)
end

-- Make it available globally for menu.lua and command palette
_G.find_projects = find_projects

-- ============================================================================
-- Command Palette (carried from previous config)
-- ============================================================================

-- Store recent executed commands for quick repeat (max 5)
_G.recent_palette_cmds = _G.recent_palette_cmds or {}

local function add_to_recent(cmd)
  for i, c in ipairs(_G.recent_palette_cmds) do
    if c == cmd then
      table.remove(_G.recent_palette_cmds, i)
      break
    end
  end
  table.insert(_G.recent_palette_cmds, 1, cmd)
  while #_G.recent_palette_cmds > 5 do
    table.remove(_G.recent_palette_cmds)
  end
end

local function reorder_with_recent(actions)
  local recent_actions = {}
  local other_actions = {}
  local recent_set = {}

  for _, cmd in ipairs(_G.recent_palette_cmds) do
    recent_set[cmd] = true
  end

  for _, action in ipairs(actions) do
    if recent_set[action.cmd] then
      table.insert(recent_actions, action)
    else
      table.insert(other_actions, action)
    end
  end

  table.sort(recent_actions, function(a, b)
    local idx_a, idx_b = 999, 999
    for i, cmd in ipairs(_G.recent_palette_cmds) do
      if cmd == a.cmd then idx_a = i end
      if cmd == b.cmd then idx_b = i end
    end
    return idx_a < idx_b
  end)

  for i, action in ipairs(recent_actions) do
    recent_actions[i] = { name = ">> " .. action.name, cmd = action.cmd }
  end

  local result = {}
  for _, action in ipairs(recent_actions) do
    table.insert(result, action)
  end
  for _, action in ipairs(other_actions) do
    table.insert(result, action)
  end
  return result
end

-- Visual mode command palette
function _G.visual_command_palette()
  local actions = {
    { name = "Toggle Comment", cmd = "normal gcc" },
    { name = "Format Selection", cmd = "lua vim.lsp.buf.format()" },
    { name = "Sort Lines", cmd = "'<,'>sort" },
    { name = "Join Lines", cmd = "'<,'>join" },
    { name = "Search Selection", cmd = "lua require('config.workspaces').grep_word()" },
    { name = "Send to Claude", cmd = "ClaudeCodeSend" },
    { name = "Uppercase", cmd = "'<,'>s/.*/\\U&/" },
    { name = "Lowercase", cmd = "'<,'>s/.*/\\L&/" },
  }

  actions = reorder_with_recent(actions)

  vim.ui.select(actions, {
    prompt = "Command Palette (Visual)",
    format_item = function(item) return item.name end,
  }, function(choice)
    if choice then
      add_to_recent(choice.cmd)
      vim.cmd(choice.cmd)
    end
  end)
end

-- Normal mode command palette
local function command_palette()
  local actions = {
    -- Files
    { name = "Find File", cmd = "lua require('config.workspaces').find_files()" },
    { name = "Find Project", cmd = "lua _G.find_projects()" },
    { name = "Find in Files (Grep)", cmd = "lua require('config.workspaces').live_grep()" },
    { name = "Recent Files", cmd = "lua Snacks.picker.recent()" },
    { name = "Open Buffers", cmd = "lua Snacks.picker.buffers()" },

    -- Code Actions
    { name = "Format Document", cmd = "lua vim.lsp.buf.format()" },
    { name = "Code Actions", cmd = "lua vim.lsp.buf.code_action()" },
    { name = "Quick Fix", cmd = "lua vim.lsp.buf.code_action({ context = { only = { 'quickfix' } } })" },
    { name = "Rename Symbol", cmd = "lua vim.lsp.buf.rename()" },
    { name = "Organize Imports", cmd = "lua vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })" },

    -- Navigation
    { name = "Go to Symbol in File", cmd = "lua Snacks.picker.lsp_symbols()" },
    { name = "Go to Symbol in Workspace", cmd = "lua Snacks.picker.lsp_workspace_symbols()" },
    { name = "Go to Definition", cmd = "lua Snacks.picker.lsp_definitions()" },
    { name = "Go to Implementation", cmd = "lua Snacks.picker.lsp_implementations()" },
    { name = "Find References", cmd = "lua Snacks.picker.lsp_references()" },

    -- Search & Replace
    { name = "Search and Replace", cmd = "lua require('grug-far').open()" },
    { name = "Search Current Word", cmd = "lua require('config.workspaces').grep_word()" },

    -- Git
    { name = "Git Status", cmd = "lua Snacks.picker.git_status()" },
    { name = "Git Commits", cmd = "lua Snacks.picker.git_log()" },
    { name = "Git Blame Line", cmd = "lua Snacks.gitbrowse()" },
    { name = "LazyGit", cmd = "lua Snacks.lazygit()" },

    -- AI (Claude Code)
    { name = "Claude: Toggle", cmd = "ClaudeCode" },
    { name = "Claude: Focus", cmd = "ClaudeCodeFocus" },
    { name = "Claude: Resume", cmd = "ClaudeCode --resume" },
    { name = "Claude: Continue", cmd = "ClaudeCode --continue" },
    { name = "Claude: Add Buffer", cmd = "ClaudeCodeAdd %" },
    { name = "Claude: Select Model", cmd = "ClaudeCodeSelectModel" },
    { name = "Claude: Accept Diff", cmd = "ClaudeCodeDiffAccept" },
    { name = "Claude: Deny Diff", cmd = "ClaudeCodeDiffDeny" },

    -- Debugging
    { name = "Debug: Start/Continue", cmd = "lua require('dap').continue()" },
    { name = "Debug: Toggle Breakpoint", cmd = "lua require('dap').toggle_breakpoint()" },
    { name = "Debug: Conditional Breakpoint", cmd = "lua require('dap').set_breakpoint(vim.fn.input('Condition: '))" },
    { name = "Debug: Step Over", cmd = "lua require('dap').step_over()" },
    { name = "Debug: Step Into", cmd = "lua require('dap').step_into()" },
    { name = "Debug: Step Out", cmd = "lua require('dap').step_out()" },
    { name = "Debug: Terminate", cmd = "lua require('dap').terminate()" },
    { name = "Debug: Toggle UI", cmd = "lua require('dapui').toggle()" },
    { name = "Debug: Hover Variable", cmd = "lua require('dap.ui.widgets').hover()" },

    -- Testing
    { name = "Test: Run Nearest", cmd = "lua require('neotest').run.run()" },
    { name = "Test: Run File", cmd = "lua require('neotest').run.run(vim.fn.expand('%'))" },
    { name = "Test: Run All", cmd = "lua require('neotest').run.run({ suite = true })" },
    { name = "Test: Toggle Summary", cmd = "lua require('neotest').summary.toggle()" },
    { name = "Test: Show Output", cmd = "lua require('neotest').output.open({ enter = true })" },

    -- Diagnostics
    { name = "Show All Diagnostics", cmd = "Trouble diagnostics" },
    { name = "Show Buffer Diagnostics", cmd = "Trouble diagnostics filter.buf=0" },

    -- Workspaces
    { name = "Workspace: Select", cmd = "WorkspaceSelect" },
    { name = "Workspace: Add Folder", cmd = "lua require('config.workspaces').add_folder_interactive()" },
    { name = "Workspace: Create", cmd = "lua vim.ui.input({ prompt = 'Workspace name: ' }, function(n) if n and n ~= '' then require('config.workspaces').create(n) end end)" },
    { name = "Workspace: Info", cmd = "WorkspaceInfo" },
    { name = "Workspace: Close", cmd = "WorkspaceClose" },
    { name = "Workspace: Find Files", cmd = "lua require('config.workspaces').find_files()" },
    { name = "Workspace: Grep", cmd = "lua require('config.workspaces').live_grep()" },

    -- Editor
    { name = "Split Down", cmd = "lua _G.smart_split(false)" },
    { name = "Split Right", cmd = "lua _G.smart_split(true)" },
    { name = "Go to Line", cmd = "lua vim.ui.input({ prompt = 'Go to line: ' }, function(n) if n then n=tonumber(n) if n then vim.api.nvim_win_set_cursor(0,{math.max(1,math.min(n,vim.api.nvim_buf_line_count(0))),0}) end end end)" },
    { name = "Duplicate Line Down", cmd = "t ." },
    { name = "Duplicate Line Up", cmd = "t .-1" },
    { name = "Toggle File Tree", cmd = "Neotree toggle" },
    { name = "Toggle Terminal", cmd = "lua _G.toggle_terminal()" },
    { name = "Toggle Word Wrap", cmd = "set wrap!" },
    { name = "Toggle Menu Bar", cmd = "lua _G.toggle_menu_bar()" },
    { name = "Restore Session", cmd = "lua require('persistence').load()" },
    { name = "Lazy (Plugin Manager)", cmd = "Lazy" },
    { name = "Mason (LSP Installer)", cmd = "Mason" },
  }

  actions = reorder_with_recent(actions)

  vim.ui.select(actions, {
    prompt = "Command Palette",
    format_item = function(item) return item.name end,
  }, function(choice)
    if choice then
      add_to_recent(choice.cmd)
      vim.cmd(choice.cmd)
    end
  end)
end

-- ============================================================================
-- VS Code / Cursor style keybindings (Ctrl = Cmd)
-- ============================================================================

-- Command palette
map("n", "<C-p>", command_palette, { desc = "Command palette" })
map("v", "<C-p>", function() _G.visual_command_palette() end, { desc = "Command palette (visual)" })
map("x", "<C-p>", function() _G.visual_command_palette() end, { desc = "Command palette (visual)" })

-- Search / Grep
map("n", "<F4>", function() ws.live_grep() end, { desc = "Search in project (grep)" })
map("n", "<C-f>", function() Snacks.picker.lines() end, { desc = "Search in current buffer" })

-- Save
map({ "n", "i", "v", "x" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Close buffer (VS Code: Ctrl+W closes tab, auto-collapses empty splits)
map("n", "<C-w>", function() _G.smart_close_buf() end, { desc = "Close buffer" })

-- Tab/Shift+Tab to cycle between layout areas (editor, sidebar, terminal, etc.)
map("n", "<Tab>", "<C-w>w", { desc = "Next window" })
map("n", "<S-Tab>", "<C-w>W", { desc = "Previous window" })

-- Toggle sidebar (Neo-tree)
map("n", "<C-b>", "<cmd>Neotree toggle<cr>", { desc = "Toggle file tree" })

-- Toggle terminal
map("n", "<C-`>", function() _G.toggle_terminal() end, { desc = "Toggle terminal" })
map("t", "<C-`>", function() _G.toggle_terminal() end, { desc = "Toggle terminal" })
map("t", "<C-]>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Toggle comment (LazyVim uses mini.comment or built-in gc)
map("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment" })
map("v", "<C-/>", "gc", { remap = true, desc = "Toggle comment" })

-- Select all
map("n", "<C-a>", "ggVG", { desc = "Select all" })

-- Clipboard: Ctrl+C / Ctrl+X / Ctrl+V (VS Code style)
map("v", "<C-c>", '"+y', { desc = "Copy" })
map("n", "<C-x>", '"+dd', { desc = "Cut line" })
map("x", "<C-x>", '"+x', { desc = "Cut selection" })
map({ "n", "v" }, "<C-v>", '"+p', { desc = "Paste" })
map("i", "<C-v>", '<C-r>+', { desc = "Paste" })
map("c", "<C-v>", "<C-r>+", { desc = "Paste" })


-- Delete/Backspace deletes selection in visual mode (VS Code behavior)
map("v", "<BS>", "d", { desc = "Delete selection" })
map("v", "<Del>", "d", { desc = "Delete selection" })

-- Shift+Arrows to select (VS Code behavior)
map("n", "<S-Up>", "Vk", { desc = "Select line up" })
map("n", "<S-Down>", "Vj", { desc = "Select line down" })
map("n", "<S-Left>", "vh", { desc = "Select char left" })
map("n", "<S-Right>", "vl", { desc = "Select char right" })
map("v", "<S-Up>", "k", { desc = "Extend selection up" })
map("v", "<S-Down>", "j", { desc = "Extend selection down" })
map("v", "<S-Left>", "h", { desc = "Extend selection left" })
map("v", "<S-Right>", "l", { desc = "Extend selection right" })
map("i", "<S-Up>", "<Esc>Vk", { desc = "Select line up" })
map("i", "<S-Down>", "<Esc>Vj", { desc = "Select line down" })
map("i", "<S-Left>", "<Esc>vh", { desc = "Select char left" })
map("i", "<S-Right>", "<Esc>vl", { desc = "Select char right" })

-- Undo/Redo
map("n", "<C-z>", "u", { desc = "Undo" })
map("n", "<C-y>", "<C-r>", { desc = "Redo" })

-- Duplicate line down/up (Alt+Shift+j/k — VS Code: Alt+Shift+Down/Up)
map("n", "<A-S-j>", "<cmd>t .<cr>", { desc = "Duplicate line down" })
map("n", "<A-S-k>", "<cmd>t .-1<cr>", { desc = "Duplicate line up" })
map("i", "<A-S-j>", "<esc><cmd>t .<cr>gi", { desc = "Duplicate line down" })
map("i", "<A-S-k>", "<esc><cmd>t .-1<cr>gi", { desc = "Duplicate line up" })
map("v", "<A-S-j>", ":'<,'>t '><cr>gv", { desc = "Duplicate selection down" })
map("v", "<A-S-k>", ":'<,'>t '<-1<cr>gv", { desc = "Duplicate selection up" })

-- Go to line (Ctrl+G — VS Code style)
map("n", "<C-g>", function()
  vim.ui.input({ prompt = "Go to line: " }, function(input)
    if input then
      local line = tonumber(input)
      if line then
        local max = vim.api.nvim_buf_line_count(0)
        line = math.max(1, math.min(line, max))
        vim.api.nvim_win_set_cursor(0, { line, 0 })
      end
    end
  end)
end, { desc = "Go to line" })

-- Quick fix / Code actions (Ctrl+. — VS Code style)
map("n", "<C-.>", vim.lsp.buf.code_action, { desc = "Quick fix / Code actions" })
map("v", "<C-.>", vim.lsp.buf.code_action, { desc = "Quick fix / Code actions" })

-- F-keys (VS Code style)
map("n", "<F2>", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<F5>", function() require("dap").continue() end, { desc = "Debug: Start/Continue" })
map("n", "<F9>", function() require("dap").toggle_breakpoint() end, { desc = "Debug: Toggle breakpoint" })
map("n", "<F10>", function() require("dap").step_over() end, { desc = "Debug: Step over" })
map("n", "<C-F10>", function()
  if _G.toggle_menu_bar then _G.toggle_menu_bar() end
end, { desc = "Toggle menu bar" })
map("n", "<F11>", function() require("dap").step_into() end, { desc = "Debug: Step into" })
map("n", "<S-F11>", function() require("dap").step_out() end, { desc = "Debug: Step out" })
map("n", "<F12>", function() Snacks.picker.lsp_definitions() end, { desc = "Go to definition" })
map("n", "<S-F12>", function() Snacks.picker.lsp_references() end, { desc = "Go to references" })

-- ============================================================================
-- Leader prefix groups
-- ============================================================================

-- File/Find (<leader>f)
map("n", "<leader>ff", function() ws.find_files() end, { desc = "Find files" })
map("n", "<leader>fp", find_projects, { desc = "Find projects" })
map("n", "<leader>fg", function() ws.live_grep() end, { desc = "Grep in project" })
map("n", "<leader>fr", function() Snacks.picker.recent() end, { desc = "Recent files" })
map("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Open buffers" })
map("n", "<leader>fc", function() ws.grep_word() end, { desc = "Find word under cursor" })

-- Code (<leader>c)
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<leader>cf", function() require("conform").format() end, { desc = "Format document" })
map("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
map("n", "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", { desc = "LSP Definitions/refs (Trouble)" })

-- Git (<leader>g)
map("n", "<leader>gg", function() Snacks.lazygit() end, { desc = "LazyGit" })
map("n", "<leader>gs", function() Snacks.picker.git_status() end, { desc = "Git status" })
map("n", "<leader>gb", function() Snacks.picker.git_log() end, { desc = "Git log" })
map("n", "<leader>gd", function() Snacks.picker.git_diff() end, { desc = "Git diff" })
map("n", "<leader>gB", function() Snacks.git.blame_line() end, { desc = "Git blame line" })
map("n", "<leader>gS", function() _G.sidebar_show_git() end, { desc = "Source Control sidebar" })

-- Search (<leader>s)
map("n", "<leader>sg", function() ws.live_grep() end, { desc = "Grep" })
map("n", "<leader>sw", function() ws.grep_word() end, { desc = "Grep word under cursor" })
map("n", "<leader>sk", function() Snacks.picker.keymaps() end, { desc = "Keymaps" })
map("n", "<leader>st", "<cmd>TodoTrouble<cr>", { desc = "Todos" })
map("n", "<leader>sr", function() Snacks.picker.resume() end, { desc = "Resume last search" })
map("n", "<leader>sh", function() Snacks.picker.help() end, { desc = "Help pages" })

-- Debug (<leader>d)
map("n", "<leader>db", function() require("dap").toggle_breakpoint() end, { desc = "Toggle breakpoint" })
map("n", "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Condition: ")) end, { desc = "Conditional breakpoint" })
map("n", "<leader>dc", function() require("dap").continue() end, { desc = "Start/Continue" })
map("n", "<leader>di", function() require("dap").step_into() end, { desc = "Step into" })
map("n", "<leader>do", function() require("dap").step_over() end, { desc = "Step over" })
map("n", "<leader>dO", function() require("dap").step_out() end, { desc = "Step out" })
map("n", "<leader>dr", function() require("dap").repl.toggle() end, { desc = "Toggle REPL" })
map("n", "<leader>dl", function() require("dap").run_last() end, { desc = "Run last" })
map("n", "<leader>dt", function() require("dap").terminate() end, { desc = "Terminate" })
map("n", "<leader>du", function() _G.toggle_dapui() end, { desc = "Toggle DAP UI" })
map("n", "<leader>dh", function() require("dap.ui.widgets").hover() end, { desc = "Hover variable" })
map("n", "<leader>da", function() require("config.dap-attach").attach_process() end, { desc = "Attach to process" })
map("n", "<leader>dA", function() require("config.dap-attach").attach_port() end, { desc = "Attach to port 9229" })
map("n", "<leader>dp", function() require("dap").pause() end, { desc = "Pause" })
map("n", "<leader>de", function()
  local dap = require("dap")
  vim.ui.select({ "All Exceptions", "Uncaught Exceptions", "None" }, {
    prompt = "Break on:",
  }, function(choice)
    if choice == "All Exceptions" then
      dap.set_exception_breakpoints({ "caught", "uncaught" })
    elseif choice == "Uncaught Exceptions" then
      dap.set_exception_breakpoints({ "uncaught" })
    elseif choice == "None" then
      dap.set_exception_breakpoints({})
    end
  end)
end, { desc = "Exception breakpoints" })

-- Diagnostics (<leader>x)
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer diagnostics (Trouble)" })
map("n", "<leader>xt", "<cmd>TodoTrouble<cr>", { desc = "Todos (Trouble)" })
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location list (Trouble)" })
map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix list (Trouble)" })

-- AI / Claude Code (<leader>a)
map({ "n", "t" }, "<A-i>", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude" })
map("n", "<leader>ac", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude" })
map("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", { desc = "Focus Claude" })
map("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>", { desc = "Resume Claude" })
map("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "Continue Claude" })
map("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", { desc = "Select Claude model" })
map("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", { desc = "Add buffer to Claude" })
map("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Accept diff" })
map("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "Deny diff" })
map("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>", { desc = "Send selection to Claude" })

-- Test (<leader>t)
map("n", "<leader>tn", function() require("neotest").run.run() end, { desc = "Run nearest test" })
map("n", "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, { desc = "Run file tests" })
map("n", "<leader>ts", function() require("neotest").summary.toggle() end, { desc = "Toggle test summary" })
map("n", "<leader>to", function() require("neotest").output.open({ enter = true }) end, { desc = "Test output" })

-- Organize imports (<leader>o)
map("n", "<leader>oi", function()
  vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
end, { desc = "Organize imports" })
map("n", "<leader>os", function()
  vim.lsp.buf.code_action({ context = { only = { "source.sortImports" } }, apply = true })
end, { desc = "Sort imports" })

-- Workspace (<leader>w)
map("n", "<leader>ws", function() ws.select() end, { desc = "Select workspace" })
map("n", "<leader>wa", function() ws.add_folder_interactive() end, { desc = "Add folder to workspace" })
map("n", "<leader>wf", function() ws.find_files() end, { desc = "Find files (workspace)" })
map("n", "<leader>wg", function() ws.live_grep() end, { desc = "Grep (workspace)" })
map("n", "<leader>ww", function() ws.grep_word() end, { desc = "Grep word (workspace)" })
map("n", "<leader>wi", function() ws.info() end, { desc = "Workspace info" })
map("n", "<leader>wc", function() ws.close() end, { desc = "Close workspace" })

-- Menu bar (<leader>M)
map("n", "<leader>M", function()
  if _G.toggle_menu_bar then _G.toggle_menu_bar() end
end, { desc = "Toggle menu bar" })
map("n", "<A-m>", function()
  if _G.toggle_menu_bar then _G.toggle_menu_bar() end
end, { desc = "Toggle menu bar" })

-- ============================================================================
-- Line moving (Alt+j/k)
-- ============================================================================
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move line down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- Visual mode indent with Tab
map("v", "<Tab>", ">gv", { desc = "Indent" })
map("v", "<S-Tab>", "<gv", { desc = "Outdent" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>noh<cr><esc>", { desc = "Clear search highlight" })

-- LSP navigation
map("n", "gd", function() Snacks.picker.lsp_definitions() end, { desc = "Go to definition" })
map("n", "gR", function() Snacks.picker.lsp_references() end, { desc = "Go to references" })
map("n", "gi", function() Snacks.picker.lsp_implementations() end, { desc = "Go to implementations" })
map("n", "gt", function() Snacks.picker.lsp_type_definitions() end, { desc = "Go to type definition" })

-- Session management
map("n", "<leader>qs", function() require("persistence").load() end, { desc = "Restore session" })
map("n", "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "Restore last session" })
map("n", "<leader>qd", function() require("persistence").stop() end, { desc = "Don't save session" })

-- Dismiss notifications
map("n", "<leader>nd", function() Snacks.notifier.hide() end, { desc = "Dismiss notifications" })
