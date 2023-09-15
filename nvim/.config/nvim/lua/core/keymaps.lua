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
local keymaps = {
	normal_mode = {
		--#region gitsigns
		-- map('n', '<leader>hs', gs.stage_hunk)
		-- map('n', '<leader>hr', gs.reset_hunk)
		-- map('v', '<leader>hs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
		-- map('v', '<leader>hr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
		-- map('n', '<leader>hS', gs.stage_buffer)
		-- map('n', '<leader>hu', gs.undo_stage_hunk)
		-- map('n', '<leader>hR', gs.reset_buffer)
		-- map('n', '<leader>hp', gs.preview_hunk)
		-- map('n', '<leader>hb', function() gs.blame_line{full=true} end)
		-- map('n', '<leader>tb', gs.toggle_current_line_blame)
		-- map('n', '<leader>hd', gs.diffthis)
		-- map('n', '<leader>hD', function() gs.diffthis('~') end)
		-- map('n', '<leader>td', gs.toggle_deleted)
		--#endregion
		-- https://nvimdev.github.io/lspsaga/definition
		-- https://nvimdev.github.io/lspsaga/diagnostic/
		-- https://nvimdev.github.io/lspsaga/finder/
		-- https://nvimdev.github.io/lspsaga/hover/
		-- https://nvimdev.github.io/lspsaga/lightbulb/
		-- https://nvimdev.github.io/lspsaga/outline/
		["<C-b>"] = { cmd = ":BufferLinePick<CR>", desc = "BufferLine pick" },
		["<C-p>"] = { cmd = ":Legendary<CR>", desc = "Legendary Menu" },
		["K"] = { cmd = ":lua vim.lsp.buf.hover()<CR>", desc = "Show documentation for what is under cursor" },
		["]d"] = { cmd = ":lua vim.diagnostic.goto_next()<CR>", desc = "Go to next diagnostic" },
		["[d"] = { cmd = ":lua vim.diagnostic.goto_prev()<CR>", desc = "Go to previous diagnostic" },
		["<leader>d"] = { cmd = ":lua vim.diagnostic.open_float()<CR>", desc = "Show line diagnostics" },
		["<leader>ca"] = { cmd = ":lua vim.lsp.buf.code_action()<CR>", desc = "See available code actions" },
		["<leader>rs"] = { cmd = ":LspRestart<CR>", desc = "Restart LSP" },
		["<C-e>"] = { cmd = ":NvimTreeToggle<CR>", desc = "Open File Explorer", opt = { silent = true } },
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
		["<leader>fg"] = { cmd = ":Telescope live_grep<CR>", desc = "Open Fuzzy Finding", opt = { silent = true } },
		["<leader>ff"] = { cmd = ":Telescope find_files<CR>", desc = "Open File Finding", opt = { silent = true } },
		["<leader>gs"] = { cmd = ":Telescope git_status<CR>", desc = "Show git status", opt = { silent = true } },
		["<leader>gb"] = { cmd = ":Telescope git_branches<CR>", desc = "Show git branches", opt = { silent = true } },
		--#endregion
		--#region Typescript
		["<leader>ru"] = { cmd = ":TypescriptRemoveUnused<CR>", desc = "Remove unused imports" },
		["<leader>oi"] = { cmd = ":TypescriptOrganizeImports<CR>", desc = "Organize imports" },
		["<leader>rf"] = { cmd = ":TypescriptRenameFile<CR>", desc = "Rename file and update file imports" },
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
		--#region Indent&MoveLines
		["<S-Tab>"] = { cmd = "<<", desc = "Indent backward" },
		["<Tab>"] = { cmd = ">>", desc = "Indent forward" },
		["<C-w>k"] = { cmd = ":m .-2<CR>==", desc = "Move the line up" },
		["<C-w>j"] = { cmd = ":m .+1<CR>==", desc = "Move the line down" },
		--#endregion
		["<C-q>"] = { cmd = close, desc = "Close window" },
		["<A-f>"] = { cmd = ":HopWord<CR>", desc = "Fast file navigation" },
		["<A-t>"] = { cmd = ":lua require('FTerm').toggle()<CR>", desc = "Toggle terminal" },
		["<Esc>"] = { cmd = ":nohl<CR>", desc = "Clear search highlights" },
		["<F5>"] = { cmd = run_code, desc = "Run Code" },
		["<C-h>"] = { cmd = "<C-w>h", desc = "Window left" },
		["<C-l>"] = { cmd = "<C-w>l", desc = "Window right" },
		["<C-j>"] = { cmd = "<C-w>j", desc = "Window down" },
		["<C-k>"] = { cmd = "<C-w>k", desc = "Window up" },
		["<C-s>"] = { cmd = "<cmd> w <CR>", desc = "Save file" },
		["<C-c>"] = { cmd = "<cmd> %y+ <CR>", desc = "Copy whole file" },
		-- ["<C-Up>"] = ":resize -2<CR>",
		-- ["<C-Down>"] = ":resize +2<CR>",
		-- ["<C-Left>"] = ":vertical resize -2<CR>",
		-- ["<C-Right>"] = ":vertical resize +2<CR>",
	},
	insert_mode = {
		["<C-b>"] = { cmd = "<ESC>^i", desc = "Beginning of line" },
		["<C-e>"] = { cmd = "<End>", desc = "End of line" },

		["<A-j>"] = { cmd = "<Esc>:m .+1<CR>==gi", desc = "Move the selected text down" },
		["<A-k>"] = { cmd = "<Esc>:m .-2<CR>==gi", desc = "Move the selected text up" },

		["<C-h>"] = { cmd = "<Left>", desc = "Move left" },
		["<C-l>"] = { cmd = "<Right>", desc = "Move right" },
		["<C-j>"] = { cmd = "<Down>", desc = "Move down" },
		["<C-k>"] = { cmd = "<Up>", desc = "Move up" },
	},
	terminal_mode = {
		["<Esc>"] = { cmd = "<C-\\><C-n>", desc = "Enter insert mode" },
	},
	visual_mode = {
		--#region Indent&MoveLines
		["<S-Tab>"] = { cmd = "<gv", desc = "Indent backward" },
		["<Tab>"] = { cmd = ">gv", desc = "Indent forward" },
		["<C-w>j"] = { cmd = ":m '>+1<CR>gv=gv", desc = "Move the selected text down" },
		["<C-w>k"] = { cmd = ":m '<-2<CR>gv=gv", desc = "Move the selected text up" },
		--#endregion
	},
	visual_block_mode = {
		["<C-w>j"] = { cmd = ":m '>+1<CR>gv=gv", desc = "Move the selected text down" },
		["<C-w>k"] = { cmd = ":m '<-2<CR>gv=gv", desc = "Move the selected text up" },
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
disable_arrows()
vim.g.copilot_no_tab_map = true
vim.g.copilot_assume_mapped = true
vim.g.copilot_tab_fallback = ""
vim.api.nvim_set_keymap("i", ",<Tab>", 'copilot#Accept("<CR>")', { silent = true, expr = true })

return keymaps
