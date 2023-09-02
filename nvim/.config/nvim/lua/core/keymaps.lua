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
		["<leader>to"] = {
			cmd = ":tabnew<CR>",
			desc = "Open new tab",
		},
		["<leader>tx"] = {
			cmd = ":tabclose<CR>",
			desc = "Close current tab",
		},
		["<leader>tn"] = {
			cmd = ":tabn<CR>",
			desc = "Go to next tab",
		},
		["<leader>tp"] = {
			cmd = ":tabp<CR>",
			desc = "Go to prev tab",
		},
		["<leader>tf"] = {
			cmd = ":tabnew %<CR>",
			desc = "Open current buffer in new tab",
		},
		["<leader>sq"] = {
			cmd = ":close<CR>",
			desc = "Split quit",
		},
		["<leader>se"] = {
			cmd = "<C-w>=",
			desc = "Split equal",
		},
		["<leader>sv"] = {
			cmd = "<C-w>v",
			desc = "Split vertically",
		},
		["<leader>sh"] = {
			cmd = "<C-w>s",
			desc = "Split horizontally",
		},
		["<leader>nh"] = {
			cmd = ":nohl<CR>",
			desc = "Clear search highlights",
		},
		["<F5>"] = {
			cmd = run_code,
			desc = "Run Code",
		},
		["j"] = {
			cmd = "v:count == 0 ? 'gj' : 'j'",
			desc = "Better Down",
			opt = {
				expr = true,
				silent = true,
			},
		},

		["k"] = {
			cmd = "v:count == 0 ? 'gk' : 'k'",
			desc = "Better Up",
			opt = {
				expr = true,
				silent = true,
			},
		},
		["<C-e>"] = {
			cmd = ":NvimTreeToggle<CR>",
			desc = "Open File Explorer",
			opt = {
				silent = true,
			},
		},
		["<C-f>"] = {
			cmd = ":Telescope live_grep<CR>",
			desc = "Open Fuzzy Finding",
			opt = {
				silent = true,
			},
		},
		["<C-p>"] = {
			cmd = ":Telescope find_files<CR>",
			desc = "Open File Finding",
			opt = {
				silent = true,
			},
		},
		["<C-g>s"] = {
			cmd = ":Telescope git_status<CR>",
			desc = "Show git status",
			opt = {
				silent = true,
			},
		},
		["<C-g>b"] = {
			cmd = ":Telescope git_branches<CR>",
			desc = "Show git branches",
			opt = {
				silent = true,
			},
		},
		["<C-q>"] = {
			cmd = close,
			desc = "Close window",
		},
		["<C-Left>"] = {
			cmd = ":bprevious<CR>",
			desc = "Go to previous buffer",
		},
		["<C-Right>"] = {
			cmd = ":bnext<CR>",
			desc = "Go to next buffer",
		},
		["<S-Tab>"] = {
			cmd = "<<",
			desc = "Indent backward",
		},
		["<Tab>"] = {
			cmd = ">>",
			desc = "Indent forward",
		},
		["<A-Up>"] = {
			cmd = ":m .+1<CR>==",
			desc = "Move the line up",
		},
		["<A-Down>"] = {
			cmd = ":m .-2<CR>==",
			desc = "Move the line down",
		},
	},
	insert_mode = {},
	terminal_mode = {

		["<Esc>"] = {
			cmd = "<C-\\><C-n>",
			desc = "Enter insert mode",
		},
	},
	visual_mode = {

		["j"] = {
			cmd = "v:count == 0 ? 'gj' : 'j'",
			desc = "Better Down",
			opt = {
				expr = true,
				silent = true,
			},
		},

		["k"] = {
			cmd = "v:count == 0 ? 'gk' : 'k'",
			desc = "Better Up",
			opt = {
				expr = true,
				silent = true,
			},
		},

		["p"] = {
			cmd = '"_dP',
			desc = "Better Paste",
		},

		["<S-Tab>"] = {
			cmd = "<gv",
			desc = "Indent backward",
		},

		["<Tab>"] = {
			cmd = ">gv",
			desc = "Indent forward",
		},

		["<A-Up>"] = {
			cmd = ":m '>+1<CR>gv=gv",
			desc = "Move the selected text up",
		},

		["<A-Down>"] = {
			cmd = ":m '<-2<CR>gv=gv",
			desc = "Move the selected text down",
		},
	},
	visual_block_mode = {

		["j"] = {
			cmd = "v:count == 0 ? 'gj' : 'j'",
			desc = "Better Down",
			opt = {
				expr = true,
				silent = true,
			},
		},

		["k"] = {
			cmd = "v:count == 0 ? 'gk' : 'k'",
			desc = "Better Up",
			opt = {
				expr = true,
				silent = true,
			},
		},

		["<A-Up>"] = {
			cmd = ":m '>+1<CR>gv=gv",
			desc = "Move the selected text up",
		},

		["<A-Down>"] = {
			cmd = ":m '<-2<CR>gv=gv",
			desc = "Move the selected text down",
		},
	},
	command_mode = {

		["<Tab>"] = {
			cmd = forward_search,
			desc = "Word Search Increment",
		},

		["<S-Tab>"] = {
			cmd = backward_search,
			desc = "Word Search Decrement",
		},
	},
}

vim.g.mapleader = " "

set_keymaps(keymaps.normal_mode, modes.normal_mode)
set_keymaps(keymaps.insert_mode, modes.insert_mode)
set_keymaps(keymaps.terminal_mode, modes.terminal_mode)
set_keymaps(keymaps.visual_mode, modes.visual_mode)
set_keymaps(keymaps.visual_block_mode, modes.visual_block_mode)
set_keymaps(keymaps.command_mode, modes.command_mode)
