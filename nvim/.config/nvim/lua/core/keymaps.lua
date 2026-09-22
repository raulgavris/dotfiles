local modes = {
	normal_mode = "n",
	insert_mode = "i",
	terminal_mode = "t",
	visual_mode = "v",
	visual_block_mode = "x",
	command_mode = "c",
}

local function forward_search()
	if vim.fn.getcmdtype() == "/" or vim.fn.getcmdtype() == "?" then
		return "<CR>/<C-r>/"
	end
	return "<C-z>"
end

local function backward_search()
	if vim.fn.getcmdtype() == "/" or vim.fn.getcmdtype() == "?" then
		return "<CR>?<C-r>/"
	end
	return "<S-Tab>"
end

-- Store recent executed commands for quick repeat (max 5)
_G.recent_palette_cmds = _G.recent_palette_cmds or {}

-- Helper to add command to recent list
local function add_to_recent(cmd)
	-- Remove if already exists
	for i, c in ipairs(_G.recent_palette_cmds) do
		if c == cmd then
			table.remove(_G.recent_palette_cmds, i)
			break
		end
	end
	-- Add to front
	table.insert(_G.recent_palette_cmds, 1, cmd)
	-- Keep only 5
	while #_G.recent_palette_cmds > 5 do
		table.remove(_G.recent_palette_cmds)
	end
end

-- Helper to reorder actions with recent commands at top
local function reorder_with_recent(actions)
	local recent_actions = {}
	local other_actions = {}
	local recent_set = {}

	-- Build set of recent commands for quick lookup
	for _, cmd in ipairs(_G.recent_palette_cmds) do
		recent_set[cmd] = true
	end

	-- Separate recent from others
	for _, action in ipairs(actions) do
		if recent_set[action.cmd] then
			table.insert(recent_actions, action)
		else
			table.insert(other_actions, action)
		end
	end

	-- Sort recent_actions by order in recent_palette_cmds
	table.sort(recent_actions, function(a, b)
		local idx_a, idx_b = 999, 999
		for i, cmd in ipairs(_G.recent_palette_cmds) do
			if cmd == a.cmd then idx_a = i end
			if cmd == b.cmd then idx_b = i end
		end
		return idx_a < idx_b
	end)

	-- Mark recent actions
	for i, action in ipairs(recent_actions) do
		recent_actions[i] = { name = "↺ " .. action.name, cmd = action.cmd }
	end

	-- Combine: recent first, then others
	local result = {}
	for _, action in ipairs(recent_actions) do
		table.insert(result, action)
	end
	for _, action in ipairs(other_actions) do
		table.insert(result, action)
	end

	return result
end

-- Visual mode command palette with selection-aware actions
function _G.visual_command_palette()
	local actions = {
		{ name = "Toggle Comment", cmd = "lua require('Comment.api').toggle.linewise(vim.fn.visualmode())" },
		{ name = "Format Selection", cmd = "lua vim.lsp.buf.format()" },
		{ name = "Sort Lines", cmd = "'<,'>sort" },
		{ name = "Join Lines", cmd = "'<,'>join" },
		{ name = "Search Selection", cmd = "lua require('grug-far').open({ prefills = { search = vim.fn.expand('<cword>') } })" },
		{ name = "Send to Claude", cmd = "ClaudeCodeSend" },
		{ name = "Uppercase", cmd = "'<,'>s/.*/\\U&/" },
		{ name = "Lowercase", cmd = "'<,'>s/.*/\\L&/" },
	}

	actions = reorder_with_recent(actions)

	vim.ui.select(actions, {
		prompt = "Command Palette (Visual)",
		format_item = function(item)
			return item.name
		end,
	}, function(choice)
		if choice then
			add_to_recent(choice.cmd)
			vim.cmd(choice.cmd)
		end
	end)
end

-- Command palette with frequent actions (normal mode)
local function command_palette()
	local actions = {
		-- Files
		{ name = "Find File", cmd = "Telescope find_files" },
		{ name = "Find in Files", cmd = "Telescope live_grep" },

		-- Code Actions
		{ name = "Format Document", cmd = "Format" },
		{ name = "Code Actions", cmd = "lua vim.lsp.buf.code_action()" },
		{ name = "Quick Fix", cmd = "lua vim.lsp.buf.code_action({ context = { only = { 'quickfix' } } })" },
		{ name = "Rename Symbol", cmd = "IncRename " .. vim.fn.expand("<cword>") },
		{ name = "Organize Imports", cmd = "lua vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })" },

		-- Tailwind CSS
		{ name = "Tailwind: Sort Classes", cmd = "TailwindSort" },
		{ name = "Tailwind: Toggle Colors", cmd = "TailwindColorToggle" },
		{ name = "Tailwind: Toggle Conceal", cmd = "TailwindConcealToggle" },
		{ name = "Tailwind: Utilities", cmd = "Telescope tailwind utilities" },

		-- TypeScript (typescript-tools)
		{ name = "TS: Organize Imports", cmd = "TSToolsOrganizeImports" },
		{ name = "TS: Sort Imports", cmd = "TSToolsSortImports" },
		{ name = "TS: Remove Unused Imports", cmd = "TSToolsRemoveUnusedImports" },
		{ name = "TS: Add Missing Imports", cmd = "TSToolsAddMissingImports" },
		{ name = "TS: Fix All Errors", cmd = "TSToolsFixAll" },
		{ name = "TS: Rename File", cmd = "TSToolsRenameFile" },
		{ name = "TS: Go to Source Definition", cmd = "TSToolsGoToSourceDefinition" },
		{ name = "TS: File References", cmd = "TSToolsFileReferences" },

		-- AI (Claude Code)
		{ name = "Claude: Toggle", cmd = "ClaudeCode" },
		{ name = "Claude: Focus", cmd = "ClaudeCodeFocus" },
		{ name = "Claude: Resume", cmd = "ClaudeCode --resume" },
		{ name = "Claude: Continue", cmd = "ClaudeCode --continue" },
		{ name = "Claude: Add Buffer", cmd = "ClaudeCodeAdd %" },
		{ name = "Claude: Select Model", cmd = "ClaudeCodeSelectModel" },
		{ name = "Claude: Accept Diff", cmd = "ClaudeCodeDiffAccept" },
		{ name = "Claude: Deny Diff", cmd = "ClaudeCodeDiffDeny" },

		-- Navigation
		{ name = "Go to Symbol in File", cmd = "Telescope lsp_document_symbols" },
		{ name = "Go to Symbol in Workspace", cmd = "Telescope lsp_workspace_symbols" },
		{ name = "Go to Definition", cmd = "Telescope lsp_definitions" },
		{ name = "Go to Implementation", cmd = "Telescope lsp_implementations" },
		{ name = "Go to Type Definition", cmd = "Telescope lsp_type_definitions" },
		{ name = "Find References", cmd = "Telescope lsp_references" },
		{ name = "Recent Files", cmd = "Telescope oldfiles" },
		{ name = "Open Buffers", cmd = "Telescope buffers" },
		{ name = "Outline (Aerial)", cmd = "AerialToggle" },

		-- Search & Replace
		{ name = "Search and Replace", cmd = "lua require('grug-far').open()" },
		{ name = "Search Current Word", cmd = "lua require('grug-far').open({ prefills = { search = vim.fn.expand('<cword>') } })" },

		-- Git
		{ name = "Git Status", cmd = "Telescope git_status" },
		{ name = "Git Commits", cmd = "Telescope git_commits" },
		{ name = "Git Blame Line", cmd = "lua require('gitsigns').blame_line({ full = true })" },
		{ name = "Git Diff", cmd = "lua require('gitsigns').diffthis()" },
		{ name = "LazyGit", cmd = "LazyGit" },
		{ name = "Diffview Open", cmd = "DiffviewOpen" },
		{ name = "Octo PR List", cmd = "Octo pr list" },

		-- Debugging
		{ name = "Debug: Start/Continue", cmd = "lua require('dap').continue()" },
		{ name = "Debug: Toggle Breakpoint", cmd = "lua require('dap').toggle_breakpoint()" },
		{ name = "Debug: Step Over", cmd = "lua require('dap').step_over()" },
		{ name = "Debug: Step Into", cmd = "lua require('dap').step_into()" },
		{ name = "Debug: Step Out", cmd = "lua require('dap').step_out()" },
		{ name = "Debug: Terminate", cmd = "lua require('dap').terminate()" },
		{ name = "Debug: Toggle UI", cmd = "lua require('dapui').toggle()" },

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
		{ name = "Workspace: Info", cmd = "WorkspaceInfo" },
		{ name = "Workspace: Close", cmd = "WorkspaceClose" },
		{ name = "Workspace: Find Files", cmd = "lua require('core.workspaces').find_files()" },
		{ name = "Workspace: Grep", cmd = "lua require('core.workspaces').live_grep()" },

		-- LSP extras
		{ name = "Incoming Calls (who calls this)", cmd = "lua vim.lsp.buf.incoming_calls()" },
		{ name = "Outgoing Calls (what this calls)", cmd = "lua vim.lsp.buf.outgoing_calls()" },
		{ name = "Toggle Inlay Hints", cmd = "lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())" },
		{ name = "Run Code Lens", cmd = "lua vim.lsp.codelens.run()" },

		-- Markdown
		{ name = "Markdown Preview", cmd = "MarkdownPreviewToggle" },

		-- Editor
		{ name = "Toggle File Tree", cmd = "Neotree toggle" },
		{ name = "Toggle Terminal", cmd = "lua require('FTerm').toggle()" },
		{ name = "Toggle Word Wrap", cmd = "set wrap!" },
		{ name = "Restore Session", cmd = "lua require('persistence').load()" },
		{ name = "Notification History", cmd = "Noice history" },
	}

	actions = reorder_with_recent(actions)

	vim.ui.select(actions, {
		prompt = "Command Palette",
		format_item = function(item)
			return item.name
		end,
	}, function(choice)
		if choice then
			add_to_recent(choice.cmd)
			vim.cmd(choice.cmd)
		end
	end)
end

local keymaps = {
	normal_mode = {
		--#region LSP
		["K"] = { cmd = ":lua vim.lsp.buf.hover()<CR>", desc = "Show hover documentation" },
		["]d"] = { cmd = ":lua vim.diagnostic.goto_next()<CR>", desc = "Next diagnostic" },
		["[d"] = { cmd = ":lua vim.diagnostic.goto_prev()<CR>", desc = "Previous diagnostic" },
		["]e"] = { cmd = ":lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })<CR>", desc = "Next error" },
		["[e"] = { cmd = ":lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })<CR>", desc = "Previous error" },
		["<leader>ld"] = { cmd = ":lua vim.diagnostic.open_float()<CR>", desc = "Line diagnostics" },
		["<leader>la"] = { cmd = ":lua vim.lsp.buf.code_action()<CR>", desc = "Code action" },
		["<leader>lr"] = { cmd = ":LspRestart<CR>", desc = "Restart LSP" },
		["<leader>rn"] = {
			cmd = function()
				return ":IncRename " .. vim.fn.expand("<cword>")
			end,
			opt = { expr = true, silent = false },
			desc = "Rename symbol (live preview)",
		},
		["<leader>lf"] = { cmd = ":Format<CR>", desc = "Format document" },
		["<leader>lt"] = { cmd = ":Telescope lsp_type_definitions<CR>", desc = "Type definitions" },
		["<leader>li"] = { cmd = ":Telescope lsp_implementations<CR>", desc = "Implementations" },
		["<leader>lD"] = { cmd = ":Telescope diagnostics bufnr=0<CR>", desc = "Buffer diagnostics" },
		["<leader>lh"] = { cmd = ":lua vim.lsp.buf.incoming_calls()<CR>", desc = "Incoming calls (who calls this)" },
		["<leader>lH"] = { cmd = ":lua vim.lsp.buf.outgoing_calls()<CR>", desc = "Outgoing calls (what this calls)" },
		["<leader>lI"] = {
			cmd = function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
			end,
			desc = "Toggle inlay hints",
		},
		["<leader>lL"] = { cmd = ":lua vim.lsp.codelens.run()<CR>", desc = "Run code lens" },
		--#endregion

		--#region Command Palette (Telescope keymaps are in telescope.lua keys table)
		["<leader>cp"] = { cmd = command_palette, desc = "Command palette" },
		--#endregion

		--#region Workspaces
		["<leader>ws"] = { cmd = ":WorkspaceSelect<CR>", desc = "Select workspace" },
		["<leader>wi"] = { cmd = ":WorkspaceInfo<CR>", desc = "Workspace info" },
		["<leader>wc"] = { cmd = ":WorkspaceClose<CR>", desc = "Close workspace" },
		["<leader>wf"] = { cmd = ":lua require('core.workspaces').find_files()<CR>", desc = "Find files (workspace)" },
		["<leader>wg"] = { cmd = ":lua require('core.workspaces').live_grep()<CR>", desc = "Grep (workspace)" },
		["<leader>ww"] = { cmd = ":lua require('core.workspaces').grep_string()<CR>", desc = "Grep word (workspace)" },
		--#endregion

		--#region Git (non-telescope — telescope git keymaps in telescope.lua keys table)
		["<leader>ge"] = { cmd = ":Neotree float git_status<CR>", desc = "Git status (Neo-tree)" },
		["<leader>gl"] = { cmd = ":lua require('gitsigns').blame_line({ full = true })<CR>", desc = "Blame line" },
		["<leader>gp"] = { cmd = ":lua require('gitsigns').preview_hunk()<CR>", desc = "Preview hunk" },
		--#endregion

		--#region Hunks (Gitsigns)
		["<leader>hs"] = { cmd = ":lua require('gitsigns').stage_hunk()<CR>", desc = "Stage hunk" },
		["<leader>hr"] = { cmd = ":lua require('gitsigns').reset_hunk()<CR>", desc = "Reset hunk" },
		["<leader>hu"] = { cmd = ":lua require('gitsigns').undo_stage_hunk()<CR>", desc = "Undo stage hunk" },
		["<leader>hS"] = { cmd = ":lua require('gitsigns').stage_buffer()<CR>", desc = "Stage buffer" },
		["<leader>hR"] = { cmd = ":lua require('gitsigns').reset_buffer()<CR>", desc = "Reset buffer" },
		["<leader>hd"] = { cmd = ":lua require('gitsigns').diffthis()<CR>", desc = "Diff this" },
		["]h"] = { cmd = ":lua require('gitsigns').nav_hunk('next')<CR>", desc = "Next hunk" },
		["[h"] = { cmd = ":lua require('gitsigns').nav_hunk('prev')<CR>", desc = "Previous hunk" },
		--#endregion

		--#region Diffview (Git diff)
		["<leader>gdo"] = { cmd = ":DiffviewOpen<CR>", desc = "Open Diffview" },
		["<leader>gdc"] = { cmd = ":DiffviewClose<CR>", desc = "Close Diffview" },
		["<leader>gdh"] = { cmd = ":DiffviewFileHistory<CR>", desc = "File History" },
		["<leader>gdH"] = { cmd = ":DiffviewFileHistory %<CR>", desc = "Current File History" },
		--#endregion

		--#region TypeScript (typescript-tools.nvim)
		["<leader>roi"] = { cmd = ":TSToolsOrganizeImports<CR>", desc = "Organize imports" },
		["<leader>ros"] = { cmd = ":TSToolsSortImports<CR>", desc = "Sort imports" },
		["<leader>ru"] = { cmd = ":TSToolsRemoveUnusedImports<CR>", desc = "Remove unused imports" },
		["<leader>ri"] = { cmd = ":TSToolsAddMissingImports<CR>", desc = "Add missing imports" },
		["<leader>rf"] = { cmd = ":TSToolsRenameFile<CR>", desc = "Rename file and update imports" },
		["<leader>ra"] = { cmd = ":TSToolsFixAll<CR>", desc = "Fix all auto-fixable errors" },
		["<leader>rd"] = { cmd = ":TSToolsGoToSourceDefinition<CR>", desc = "Go to source definition" },
		--#endregion

		--#region Buffer
		["<leader>bd"] = { cmd = ":lua require('mini.bufremove').delete()<CR>", desc = "Delete buffer" },
		["<leader>bD"] = { cmd = ":lua require('mini.bufremove').delete(0, true)<CR>", desc = "Force delete buffer" },
		["<leader>bo"] = {
			cmd = function()
				local current = vim.api.nvim_get_current_buf()
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if buf ~= current and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
						pcall(vim.api.nvim_buf_delete, buf, {})
					end
				end
			end,
			desc = "Close other buffers",
		},
		--#endregion

		--#region Splits
		["<leader>sq"] = { cmd = ":close<CR>", desc = "Close split" },
		["<leader>se"] = { cmd = "<C-w>=", desc = "Equalize splits" },
		["<leader>sv"] = { cmd = "<C-w>v", desc = "Split vertically" },
		["<leader>sh"] = { cmd = "<C-w>s", desc = "Split horizontally" },
		--#endregion

		--#region Move Lines
		["<A-k>"] = { cmd = ":m .-2<CR>==", desc = "Move line up" },
		["<A-j>"] = { cmd = ":m .+1<CR>==", desc = "Move line down" },
		--#endregion

		--#region File tree (Neo-tree)
		["<leader>e"] = { cmd = ":Neotree toggle<CR>", desc = "Toggle file tree" },
		["<leader>E"] = { cmd = ":Neotree focus<CR>", desc = "Focus file tree" },
		--#endregion

		--#region Aerial (Outline)
		["<leader>oo"] = { cmd = ":AerialToggle!<CR>", desc = "Toggle Outline" },
		["<leader>oO"] = { cmd = ":AerialOpen<CR>", desc = "Open Outline" },
		--#endregion

		--#region Persistence (Session)
		["<leader>qs"] = { cmd = ":lua require('persistence').load()<CR>", desc = "Restore Session" },
		["<leader>ql"] = { cmd = ":lua require('persistence').load({ last = true })<CR>", desc = "Restore Last Session" },
		["<leader>qd"] = { cmd = ":lua require('persistence').stop()<CR>", desc = "Don't Save Current Session" },
		--#endregion

		--#region Todo Comments
		["]t"] = { cmd = ":lua require('todo-comments').jump_next()<CR>", desc = "Next todo comment" },
		["[t"] = { cmd = ":lua require('todo-comments').jump_prev()<CR>", desc = "Previous todo comment" },
		["<leader>xt"] = { cmd = ":TodoTrouble<CR>", desc = "Todo (Trouble)" },
		["<leader>xT"] = { cmd = ":TodoTrouble keywords=TODO,FIX,FIXME<CR>", desc = "Todo/Fix/Fixme (Trouble)" },
		--#endregion

		--#region Trouble (Diagnostics)
		["<leader>xx"] = { cmd = ":Trouble diagnostics toggle<CR>", desc = "Diagnostics (Trouble)" },
		["<leader>xX"] = { cmd = ":Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer Diagnostics (Trouble)" },
		["<leader>xs"] = { cmd = ":Trouble symbols toggle focus=false<CR>", desc = "Symbols (Trouble)" },
		["<leader>xl"] = { cmd = ":Trouble lsp toggle focus=false win.position=right<CR>", desc = "LSP Definitions/references (Trouble)" },
		["<leader>xL"] = { cmd = ":Trouble loclist toggle<CR>", desc = "Location List (Trouble)" },
		["<leader>xQ"] = { cmd = ":Trouble qflist toggle<CR>", desc = "Quickfix List (Trouble)" },
		--#endregion

		--#region Flash (Fast navigation)
		["s"] = { cmd = ":lua require('flash').jump()<CR>", desc = "Flash" },
		["S"] = { cmd = ":lua require('flash').treesitter()<CR>", desc = "Flash Treesitter" },
		--#endregion

		--#region Claude Code (AI)
		["<leader>ac"] = { cmd = ":ClaudeCode<CR>", desc = "Toggle Claude" },
		["<leader>af"] = { cmd = ":ClaudeCodeFocus<CR>", desc = "Focus Claude" },
		["<leader>ar"] = { cmd = ":ClaudeCode --resume<CR>", desc = "Resume Claude" },
		["<leader>aC"] = { cmd = ":ClaudeCode --continue<CR>", desc = "Continue Claude" },
		["<leader>am"] = { cmd = ":ClaudeCodeSelectModel<CR>", desc = "Select Claude model" },
		["<leader>ab"] = { cmd = ":ClaudeCodeAdd %<CR>", desc = "Add current buffer to Claude" },
		["<leader>aa"] = { cmd = ":ClaudeCodeDiffAccept<CR>", desc = "Accept diff" },
		["<leader>ad"] = { cmd = ":ClaudeCodeDiffDeny<CR>", desc = "Deny diff" },
		--#endregion

		--#region Window navigation (fallback before vim-tmux-navigator loads via VeryLazy)
		["<C-h>"] = { cmd = "<C-w>h", desc = "Window left" },
		["<C-l>"] = { cmd = "<C-w>l", desc = "Window right" },
		["<C-j>"] = { cmd = "<C-w>j", desc = "Window down" },
		["<C-k>"] = { cmd = "<C-w>k", desc = "Window up" },
		--#endregion

		--#region Misc
		["<Esc>"] = { cmd = ":nohl<CR>", desc = "Clear search highlights" },
		["<leader>Y"] = { cmd = "<cmd> %y+ <CR>", desc = "Yank entire file" },
		["<leader>nd"] = { cmd = ":lua require('noice').cmd('dismiss')<CR>", desc = "Dismiss notifications" },
		["<leader>nh"] = { cmd = ":Noice history<CR>", desc = "Notification history" },
		--#endregion
	},
	insert_mode = {
		-- Move lines
		["<A-j>"] = { cmd = "<Esc>:m .+1<CR>==gi", desc = "Move line down" },
		["<A-k>"] = { cmd = "<Esc>:m .-2<CR>==gi", desc = "Move line up" },
	},
	terminal_mode = {
		["<Esc>"] = { cmd = "<C-\\><C-n>", desc = "Exit terminal mode" },
	},
	visual_mode = {
		--#region Indent & Move Lines
		["<S-Tab>"] = { cmd = "<gv", desc = "Indent backward" },
		["<Tab>"] = { cmd = ">gv", desc = "Indent forward" },
		["<A-j>"] = { cmd = ":m '>+1<CR>gv=gv", desc = "Move selected text down" },
		["<A-k>"] = { cmd = ":m '<-2<CR>gv=gv", desc = "Move selected text up" },
		--#endregion

		-- Join lines
		["<leader>j"] = { cmd = ":join<CR>", desc = "Join selected lines" },

		-- Format selection
		["<leader>lf"] = { cmd = ":lua vim.lsp.buf.format()<CR>", desc = "Format selection" },

		-- Search for selected text
		["<leader>fc"] = { cmd = '"zy:Telescope grep_string default_text=<C-r>z<CR>', desc = "Search selected text" },

		-- Grug-far search selection
		["<leader>Sw"] = { cmd = ":lua require('grug-far').open({ prefills = { search = vim.fn.expand('<cword>') } })<CR>", desc = "Search current selection" },

		-- Claude Code send selection
		["<leader>as"] = { cmd = ":ClaudeCodeSend<CR>", desc = "Send to Claude" },

		-- Flash
		["s"] = { cmd = ":lua require('flash').jump()<CR>", desc = "Flash" },
		["S"] = { cmd = ":lua require('flash').treesitter()<CR>", desc = "Flash Treesitter" },

		-- Command palette in visual mode
		["<leader>cp"] = { cmd = "<Esc><Cmd>lua _G.visual_command_palette()<CR>", desc = "Command palette" },
	},
	visual_block_mode = {
		-- Move lines
		["<A-j>"] = { cmd = ":m '>+1<CR>gv=gv", desc = "Move selected text down" },
		["<A-k>"] = { cmd = ":m '<-2<CR>gv=gv", desc = "Move selected text up" },

		-- Flash
		["s"] = { cmd = ":lua require('flash').jump()<CR>", desc = "Flash" },
		["S"] = { cmd = ":lua require('flash').treesitter()<CR>", desc = "Flash Treesitter" },

		-- Command palette in visual block mode
		["<leader>cp"] = { cmd = "<Esc><Cmd>lua _G.visual_command_palette()<CR>", desc = "Command palette" },
	},
	command_mode = {
		["<Tab>"] = { cmd = forward_search, desc = "Word Search Increment" },
		["<S-Tab>"] = { cmd = backward_search, desc = "Word Search Decrement" },
	},
}

set_keymaps(keymaps.normal_mode, modes.normal_mode)
set_keymaps(keymaps.insert_mode, modes.insert_mode)
set_keymaps(keymaps.terminal_mode, modes.terminal_mode)
set_keymaps(keymaps.visual_mode, modes.visual_mode)
set_keymaps(keymaps.visual_block_mode, modes.visual_block_mode)
set_keymaps(keymaps.command_mode, modes.command_mode)

-- Additional keymaps that need special handling (operator-pending mode)
vim.keymap.set("o", "r", function() require("flash").remote() end, { desc = "Remote Flash" })
vim.keymap.set({ "o", "x" }, "R", function() require("flash").treesitter_search() end, { desc = "Treesitter Search" })
vim.keymap.set("c", "<C-s>", function() require("flash").toggle() end, { desc = "Toggle Flash Search" })

return keymaps
