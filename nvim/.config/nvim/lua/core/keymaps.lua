local fn = vim.fn

local modes = {
	normal_mode = "n",
	insert_mode = "i",
	terminal_mode = "t",
	visual_mode = "v",
	visual_block_mode = "x",
	command_mode = "c",
}

local function close()
	if vim.bo.buftype == "terminal" then
		vim.cmd("Bdelete!")
		vim.cmd("silent! close")
	elseif #vim.api.nvim_list_wins() > 1 then
		vim.cmd("silent! close")
	else
		vim.notify("Can't Close Window", vim.log.levels.WARN, {
			title = "Close Window",
		})
	end
end

local function forward_search()
	if fn.getcmdtype() == "/" or fn.getcmdtype() == "?" then
		return "<CR>/<C-r>/"
	end
	return "<C-z>"
end

local function backward_search()
	if fn.getcmdtype() == "/" or fn.getcmdtype() == "?" then
		return "<CR>?<C-r>/"
	end
	return "<S-Tab>"
end

-- Store last executed command for quick repeat
_G.last_palette_cmd = nil

-- Visual mode command palette with selection-aware actions
function _G.visual_command_palette()
	local actions = {
		{ name = "Toggle Comment", cmd = "lua require('Comment.api').toggle.linewise(vim.fn.visualmode())" },
		{ name = "Format Selection", cmd = "lua vim.lsp.buf.format()" },
		{ name = "Sort Lines", cmd = "'<,'>sort" },
		{ name = "Join Lines", cmd = "'<,'>join" },
		{ name = "Search Selection", cmd = "lua require('spectre').open_visual()" },
		{ name = "Send to Claude", cmd = "ClaudeCodeSend" },
		{ name = "Uppercase", cmd = "'<,'>s/.*/\\U&/" },
		{ name = "Lowercase", cmd = "'<,'>s/.*/\\L&/" },
	}

	-- Move last command to top if exists
	if _G.last_palette_cmd then
		for i, action in ipairs(actions) do
			if action.cmd == _G.last_palette_cmd then
				table.remove(actions, i)
				table.insert(actions, 1, { name = "↺ " .. action.name, cmd = action.cmd })
				break
			end
		end
	end

	vim.ui.select(actions, {
		prompt = "Command Palette (Visual)",
		format_item = function(item)
			return item.name
		end,
	}, function(choice)
		if choice then
			_G.last_palette_cmd = choice.cmd
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
		{ name = "Format Document", cmd = "lua vim.lsp.buf.format()" },
		{ name = "Code Actions", cmd = "lua vim.lsp.buf.code_action()" },
		{ name = "Quick Fix", cmd = "lua vim.lsp.buf.code_action({ context = { only = { 'quickfix' } } })" },
		{ name = "Rename Symbol", cmd = "lua vim.lsp.buf.rename()" },
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
		{ name = "Find References", cmd = "Telescope lsp_references" },
		{ name = "Recent Files", cmd = "Telescope oldfiles" },
		{ name = "Open Buffers", cmd = "Telescope buffers" },
		{ name = "Outline (Aerial)", cmd = "AerialToggle" },

		-- Search & Replace
		{ name = "Search and Replace", cmd = "lua require('spectre').toggle()" },
		{ name = "Search Current Word", cmd = "lua require('spectre').open_visual({ select_word = true })" },

		-- Git
		{ name = "Git Status", cmd = "Telescope git_status" },
		{ name = "Git Commits", cmd = "Telescope git_commits" },
		{ name = "Git Blame Line", cmd = "lua require('gitsigns').blame_line({ full = true })" },
		{ name = "Git Diff", cmd = "lua require('gitsigns').diffthis()" },
		{ name = "LazyGit", cmd = "LazyGit" },
		{ name = "Diffview Open", cmd = "DiffviewOpen" },

		-- Debugging
		{ name = "Debug: Start/Continue", cmd = "lua require('dap').continue()" },
		{ name = "Debug: Toggle Breakpoint", cmd = "lua require('dap').toggle_breakpoint()" },
		{ name = "Debug: Conditional Breakpoint", cmd = "lua require('dap').set_breakpoint(vim.fn.input('Condition: '))" },
		{ name = "Debug: Step Over (next)", cmd = "lua require('dap').step_over()" },
		{ name = "Debug: Step Into", cmd = "lua require('dap').step_into()" },
		{ name = "Debug: Step Out (finish)", cmd = "lua require('dap').step_out()" },
		{ name = "Debug: Pause", cmd = "lua require('dap').pause()" },
		{ name = "Debug: Restart", cmd = "lua require('dap').restart()" },
		{ name = "Debug: Terminate", cmd = "lua require('dap').terminate()" },
		{ name = "Debug: Toggle UI", cmd = "lua require('dapui').toggle()" },
		{ name = "Debug: Toggle REPL", cmd = "lua require('dap').repl.toggle()" },
		{ name = "Debug: Hover Variable", cmd = "lua require('dap.ui.widgets').hover()" },
		{ name = "Debug: Run Last", cmd = "lua require('dap').run_last()" },

		-- Testing
		{ name = "Test: Run Nearest", cmd = "lua require('neotest').run.run()" },
		{ name = "Test: Run File", cmd = "lua require('neotest').run.run(vim.fn.expand('%'))" },
		{ name = "Test: Run All", cmd = "lua require('neotest').run.run({ suite = true })" },
		{ name = "Test: Run Last", cmd = "lua require('neotest').run.run_last()" },
		{ name = "Test: Toggle Summary", cmd = "lua require('neotest').summary.toggle()" },
		{ name = "Test: Show Output", cmd = "lua require('neotest').output.open({ enter = true })" },
		{ name = "Test: Debug Nearest", cmd = "lua require('neotest').run.run({ strategy = 'dap' })" },
		{ name = "Test: Stop", cmd = "lua require('neotest').run.stop()" },

		-- Diagnostics
		{ name = "Show All Diagnostics", cmd = "Trouble diagnostics" },
		{ name = "Show Buffer Diagnostics", cmd = "Trouble diagnostics filter.buf=0" },

		-- Editor
		{ name = "Toggle File Tree", cmd = "Neotree toggle" },
		{ name = "Toggle Terminal", cmd = "lua require('FTerm').toggle()" },
		{ name = "Toggle Word Wrap", cmd = "set wrap!" },
		{ name = "Restore Session", cmd = "lua require('persistence').load()" },
	}

	-- Move last command to top if exists
	if _G.last_palette_cmd then
		for i, action in ipairs(actions) do
			if action.cmd == _G.last_palette_cmd then
				table.remove(actions, i)
				table.insert(actions, 1, { name = "↺ " .. action.name, cmd = action.cmd })
				break
			end
		end
	end

	vim.ui.select(actions, {
		prompt = "Command Palette",
		format_item = function(item)
			return item.name
		end,
	}, function(choice)
		if choice then
			_G.last_palette_cmd = choice.cmd
			vim.cmd(choice.cmd)
		end
	end)
end

-- Search current buffer
local function search_current_buffer()
	require("telescope.builtin").current_buffer_fuzzy_find({
		previewer = false,
		layout_config = { width = 0.8 },
	})
end

local keymaps = {
	normal_mode = {
		--#region VS Code / Cursor style keybindings (Ctrl = Cmd)
		["<C-p>"] = { cmd = ":Telescope find_files<CR>", desc = "Quick open file" },
		["<C-P>"] = { cmd = command_palette, desc = "Command palette" },
		["<leader>cp"] = { cmd = command_palette, desc = "Command palette" },
		["<C-f>"] = { cmd = search_current_buffer, desc = "Search in current file" },
		["<C-g>"] = { cmd = ":Telescope live_grep<CR>", desc = "Search in project" },
		["<C-b>"] = { cmd = ":Neotree toggle<CR>", desc = "Toggle file tree" },
		["<C-s>"] = { cmd = ":w<CR>", desc = "Save file" },
		["<C-w>"] = { cmd = ":bdelete<CR>", desc = "Close buffer" },
		["<C-z>"] = { cmd = "u", desc = "Undo" },
		["<C-y>"] = { cmd = "<C-r>", desc = "Redo" },
		--#endregion

		--#region LSP
		["K"] = { cmd = ":lua vim.lsp.buf.hover()<CR>", desc = "Show documentation for what is under cursor" },
		["]d"] = { cmd = ":lua vim.diagnostic.goto_next()<CR>", desc = "Go to next diagnostic" },
		["[d"] = { cmd = ":lua vim.diagnostic.goto_prev()<CR>", desc = "Go to previous diagnostic" },
		["<leader>d"] = { cmd = ":lua vim.diagnostic.open_float()<CR>", desc = "Show line diagnostics" },
		["<leader>ca"] = { cmd = ":lua vim.lsp.buf.code_action()<CR>", desc = "See available code actions" },
		["<leader>rs"] = { cmd = ":LspRestart<CR>", desc = "Restart LSP" },
		["<leader>rn"] = { cmd = ":lua vim.lsp.buf.rename()<CR>", desc = "Rename symbol" },
		["<leader>fm"] = { cmd = ":lua vim.lsp.buf.format()<CR>", desc = "Format document" },
		--#endregion

		--#region Harpoon
		["<leader>hp"] = { cmd = ":lua require('harpoon.ui').nav_prev()<CR>", desc = "Go to previous harpoon mark" },
		["<leader>hn"] = { cmd = ":lua require('harpoon.ui').nav_next()<CR>", desc = "Go to next harpoon mark" },
		["<leader>hm"] = { cmd = ":lua require('harpoon.mark').add_file()<CR>", desc = "Mark file with harpoon" },
		--#endregion

		--#region Telescope
		["gt"] = { cmd = ":Telescope lsp_type_definitions<CR>", desc = "Show LSP type definitions" },
		["gi"] = { cmd = ":Telescope lsp_implementations<CR>", desc = "Show LSP implementations" },
		["gd"] = { cmd = ":Telescope lsp_definitions<CR>", desc = "Show LSP definitions" },
		["gR"] = { cmd = ":Telescope lsp_references<CR>", desc = "Show LSP references" },
		["<leader>u"] = { cmd = ":Telescope undo<CR>", desc = "Show undos" },
		["<leader>D"] = { cmd = ":Telescope diagnostics bufnr=0<CR>", desc = "Show buffer diagnostics" },
		["<leader>gfc"] = { cmd = ":Telescope git_bcommits<CR>", desc = "Show git commits for current buffer" },
		["<leader>gc"] = { cmd = ":Telescope git_commits<CR>", desc = "Show git commits" },
		["<leader>hf"] = { cmd = ":Telescope harpoon marks<CR>", desc = "Show harpoon marks" },
		["<leader>fb"] = { cmd = ":Telescope buffers<CR>", desc = "Show open buffers" },
		["<leader>fc"] = { cmd = ":Telescope grep_string<CR>", desc = "Find string under cursor in cwd" },
		["<leader>fr"] = { cmd = ":Telescope oldfiles<CR>", desc = "Fuzzy find recent files" },
		["<leader>fg"] = { cmd = ":Telescope live_grep<CR>", desc = "Search in project" },
		["<leader>ff"] = { cmd = ":Telescope find_files<CR>", desc = "Quick open file" },
		["<leader>gs"] = { cmd = ":Telescope git_status<CR>", desc = "Show git status" },
		["<leader>gb"] = { cmd = ":Telescope git_branches<CR>", desc = "Show git branches" },
		["<leader>ch"] = { cmd = ":Telescope command_history<CR>", desc = "Command history" },
		["<leader>:"] = { cmd = ":Telescope commands<CR>", desc = "All commands" },
		--#endregion

		--#region TypeScript (typescript-tools.nvim)
		["<leader>oi"] = { cmd = ":TSToolsOrganizeImports<CR>", desc = "Organize imports" },
		["<leader>os"] = { cmd = ":TSToolsSortImports<CR>", desc = "Sort imports" },
		["<leader>ru"] = { cmd = ":TSToolsRemoveUnusedImports<CR>", desc = "Remove unused imports" },
		["<leader>ri"] = { cmd = ":TSToolsAddMissingImports<CR>", desc = "Add missing imports" },
		["<leader>rf"] = { cmd = ":TSToolsRenameFile<CR>", desc = "Rename file and update imports" },
		["<leader>ra"] = { cmd = ":TSToolsFixAll<CR>", desc = "Fix all auto-fixable errors" },
		["<leader>rd"] = { cmd = ":TSToolsGoToSourceDefinition<CR>", desc = "Go to source definition" },
		--#endregion

		--#region Tabs
		["<leader>to"] = { cmd = ":tabnew<CR>", desc = "Open new tab" },
		["<leader>tx"] = { cmd = ":tabclose<CR>", desc = "Close current tab" },
		["<leader>tn"] = { cmd = ":tabn<CR>", desc = "Go to next tab" },
		["<leader>tp"] = { cmd = ":tabp<CR>", desc = "Go to prev tab" },
		["<leader>tf"] = { cmd = ":tabnew %<CR>", desc = "Open current buffer in new tab" },
		--#endregion

		--#region Splits
		["<leader>sq"] = { cmd = ":close<CR>", desc = "Split quit" },
		["<leader>se"] = { cmd = "<C-w>=", desc = "Split equal" },
		["<leader>sv"] = { cmd = "<C-w>v", desc = "Split vertically" },
		["<leader>sh"] = { cmd = "<C-w>s", desc = "Split horizontally" },
		--#endregion

		--#region Indent & Move Lines
		["<"] = { cmd = "<<", desc = "Indent backward" },
		[">"] = { cmd = ">>", desc = "Indent forward" },
		["<A-k>"] = { cmd = ":m .-2<CR>==", desc = "Move line up" },
		["<A-j>"] = { cmd = ":m .+1<CR>==", desc = "Move line down" },
		--#endregion

		--#region File tree (Neo-tree)
		["<C-e>"] = { cmd = ":Neotree toggle<CR>", desc = "Toggle file tree" },
		["<leader>e"] = { cmd = ":Neotree focus<CR>", desc = "Focus file tree" },
		["<leader>ge"] = { cmd = ":Neotree float git_status<CR>", desc = "Git status (Neo-tree)" },
		--#endregion

		--#region Debug (DAP)
		["<leader>db"] = { cmd = ":lua require('dap').toggle_breakpoint()<CR>", desc = "Toggle breakpoint" },
		["<leader>dB"] = { cmd = ":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", desc = "Conditional breakpoint" },
		["<leader>dc"] = { cmd = ":lua require('dap').continue()<CR>", desc = "Start/Continue debugger" },
		["<leader>di"] = { cmd = ":lua require('dap').step_into()<CR>", desc = "Step into" },
		["<leader>do"] = { cmd = ":lua require('dap').step_over()<CR>", desc = "Step over" },
		["<leader>dO"] = { cmd = ":lua require('dap').step_out()<CR>", desc = "Step out" },
		["<leader>dr"] = { cmd = ":lua require('dap').repl.toggle()<CR>", desc = "Toggle REPL" },
		["<leader>dl"] = { cmd = ":lua require('dap').run_last()<CR>", desc = "Run last" },
		["<leader>dt"] = { cmd = ":lua require('dap').terminate()<CR>", desc = "Terminate debugger" },
		["<leader>du"] = { cmd = ":lua require('dapui').toggle()<CR>", desc = "Toggle DAP UI" },
		["<leader>dh"] = { cmd = ":lua require('dap.ui.widgets').hover()<CR>", desc = "Hover variables" },
		["<leader>dn"] = { cmd = ":lua require('dap').step_over()<CR>", desc = "Step over (next)" },
		["<leader>ds"] = { cmd = ":lua require('dap').step_into()<CR>", desc = "Step into" },
		["<leader>df"] = { cmd = ":lua require('dap').step_out()<CR>", desc = "Step out (finish)" },
		["<leader>dp"] = { cmd = ":lua require('dap').pause()<CR>", desc = "Pause" },
		["<leader>dR"] = { cmd = ":lua require('dap').restart()<CR>", desc = "Restart" },
		--#endregion

		--#region Aerial (Outline)
		["<leader>o"] = { cmd = ":AerialToggle!<CR>", desc = "Toggle Outline (Aerial)" },
		["<leader>O"] = { cmd = ":AerialOpen<CR>", desc = "Open Outline" },
		--#endregion

		--#region Spectre (Search & Replace)
		["<leader>S"] = { cmd = ":lua require('spectre').toggle()<CR>", desc = "Toggle Spectre (Search & Replace)" },
		["<leader>sw"] = { cmd = ":lua require('spectre').open_visual({ select_word = true })<CR>", desc = "Search current word" },
		["<leader>sp"] = { cmd = ":lua require('spectre').open_file_search({ select_word = true })<CR>", desc = "Search in current file" },
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
		["<leader>st"] = { cmd = ":TodoTelescope<CR>", desc = "Todo (Telescope)" },
		["<leader>sT"] = { cmd = ":TodoTelescope keywords=TODO,FIX,FIXME<CR>", desc = "Todo/Fix/Fixme (Telescope)" },
		--#endregion

		--#region Trouble (Diagnostics)
		["<leader>xx"] = { cmd = ":Trouble diagnostics toggle<CR>", desc = "Diagnostics (Trouble)" },
		["<leader>xX"] = { cmd = ":Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer Diagnostics (Trouble)" },
		["<leader>cs"] = { cmd = ":Trouble symbols toggle focus=false<CR>", desc = "Symbols (Trouble)" },
		["<leader>cl"] = { cmd = ":Trouble lsp toggle focus=false win.position=right<CR>", desc = "LSP Definitions/references (Trouble)" },
		["<leader>xL"] = { cmd = ":Trouble loclist toggle<CR>", desc = "Location List (Trouble)" },
		["<leader>xQ"] = { cmd = ":Trouble qflist toggle<CR>", desc = "Quickfix List (Trouble)" },
		--#endregion

		--#region Diffview (Git diff)
		["<leader>gdo"] = { cmd = ":DiffviewOpen<CR>", desc = "Open Diffview" },
		["<leader>gdc"] = { cmd = ":DiffviewClose<CR>", desc = "Close Diffview" },
		["<leader>gdh"] = { cmd = ":DiffviewFileHistory<CR>", desc = "File History" },
		["<leader>gdH"] = { cmd = ":DiffviewFileHistory %<CR>", desc = "Current File History" },
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

		--#region Window navigation
		["<C-q>"] = { cmd = close, desc = "Close window" },
		["<C-h>"] = { cmd = "<C-w>h", desc = "Window left" },
		["<C-l>"] = { cmd = "<C-w>l", desc = "Window right" },
		["<C-j>"] = { cmd = "<C-w>j", desc = "Window down" },
		["<C-k>"] = { cmd = "<C-w>k", desc = "Window up" },
		--#endregion

		--#region Jump navigation
		["<C-o>"] = { cmd = "<C-o>", desc = "Jump back" },
		["<C-i>"] = { cmd = "<C-i>", desc = "Jump forward" },
		["<A-Left>"] = { cmd = "<C-o>", desc = "Jump back" },
		["<A-Right>"] = { cmd = "<C-i>", desc = "Jump forward" },
		--#endregion

		--#region Comment
		["<leader>c"] = { cmd = ":lua require('Comment.api').toggle.linewise.current()<CR>", desc = "Toggle Comment" },
		--#endregion

		--#region Misc
		["<A-f>"] = { cmd = ":HopWord<CR>", desc = "Fast file navigation" },
		["<A-t>"] = { cmd = ":lua require('FTerm').toggle()<CR>", desc = "Toggle terminal" },
		["<Esc>"] = { cmd = ":nohl<CR>", desc = "Clear search highlights" },
		["<C-c>"] = { cmd = "<cmd> %y+ <CR>", desc = "Copy whole file" },
		--#endregion
	},
	insert_mode = {
		["<C-b>"] = { cmd = "<ESC>^i", desc = "Beginning of line" },
		["<C-e>"] = { cmd = "<End>", desc = "End of line" },

		["<A-j>"] = { cmd = "<Esc>:m .+1<CR>==gi", desc = "Move line down" },
		["<A-k>"] = { cmd = "<Esc>:m .-2<CR>==gi", desc = "Move line up" },

		["<C-h>"] = { cmd = "<Left>", desc = "Move left" },
		["<C-l>"] = { cmd = "<Right>", desc = "Move right" },
		["<C-j>"] = { cmd = "<Down>", desc = "Move down" },
		["<C-k>"] = { cmd = "<Up>", desc = "Move up" },

		["<C-s>"] = { cmd = "<Esc>:w<CR>a", desc = "Save file" },
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
		["<leader>fm"] = { cmd = ":lua vim.lsp.buf.format()<CR>", desc = "Format selection" },

		-- Search for selected text
		["<leader>fc"] = { cmd = '"zy:Telescope grep_string default_text=<C-r>z<CR>', desc = "Search selected text" },

		-- Spectre search selection
		["<leader>sw"] = { cmd = ":lua require('spectre').open_visual()<CR>", desc = "Search current selection" },

		-- Claude Code send selection
		["<leader>as"] = { cmd = ":ClaudeCodeSend<CR>", desc = "Send to Claude" },

		-- Flash
		["s"] = { cmd = ":lua require('flash').jump()<CR>", desc = "Flash" },
		["S"] = { cmd = ":lua require('flash').treesitter()<CR>", desc = "Flash Treesitter" },

		-- Comment
		["<leader>c"] = { cmd = "<Esc><Cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", desc = "Toggle Comment" },

		-- Command palette in visual mode
		["<C-P>"] = { cmd = "<Esc><Cmd>lua _G.visual_command_palette()<CR>", desc = "Command palette" },
		["<leader>cp"] = { cmd = "<Esc><Cmd>lua _G.visual_command_palette()<CR>", desc = "Command palette" },
	},
	visual_block_mode = {
		-- Move lines
		["<A-j>"] = { cmd = ":m '>+1<CR>gv=gv", desc = "Move selected text down" },
		["<A-k>"] = { cmd = ":m '<-2<CR>gv=gv", desc = "Move selected text up" },

		-- Flash
		["s"] = { cmd = ":lua require('flash').jump()<CR>", desc = "Flash" },
		["S"] = { cmd = ":lua require('flash').treesitter()<CR>", desc = "Flash Treesitter" },

		-- Comment
		["<leader>c"] = { cmd = "<Esc><Cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", desc = "Toggle Comment" },

		-- Command palette in visual block mode
		["<C-P>"] = { cmd = "<Esc><Cmd>lua _G.visual_command_palette()<CR>", desc = "Command palette" },
		["<leader>cp"] = { cmd = "<Esc><Cmd>lua _G.visual_command_palette()<CR>", desc = "Command palette" },
	},
	command_mode = {
		["<Tab>"] = { cmd = forward_search, desc = "Word Search Increment" },
		["<S-Tab>"] = { cmd = backward_search, desc = "Word Search Decrement" },
	},
}

vim.g.mapleader = " "

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
