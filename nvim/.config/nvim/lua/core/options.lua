local options = {
	backup = false, -- creates a backup file
	conceallevel = 0, -- so that `` is visible in markdown files
	fileencoding = "utf-8", -- the encoding written to a file
	ignorecase = true, -- ignore case in search patterns
	mouse = "a", -- allow the mouse to be used in neovim
	pumheight = 8, -- pop up menu height
	pumblend = 10, -- transparency of pop-up menu
	showmode = false, -- we don't need to see things like -- INSERT -- anymore
	smartcase = true, -- smart case
	smartindent = true, -- make indenting smarter again
	splitbelow = true, -- force all horizontal splits to go below current window
	splitright = true, -- force all vertical splits to go to the right of current window
	swapfile = false, -- creates a swapfile
	-- timeoutlen removed: which-key sets it to 300 in its init
	undofile = true, -- enable persistent undo
	updatetime = 100, -- faster completion (4000ms default)
	writebackup = false, -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
	expandtab = true, -- convert tabs to spaces
	shiftwidth = 2, -- the number of spaces inserted for each indentation
	tabstop = 2, -- insert 2 spaces for a tab
	cursorline = true, -- highlight the current line
	number = true, -- set numbered lines
	relativenumber = true, -- set relative numbered lines
	numberwidth = 4, -- set number column width to 4 {default 4}
	signcolumn = "yes", -- always show the sign column, otherwise it would shift the text each time
	wrap = false, -- display lines as one long line
	scrolloff = 8, -- minimal number of screen lines above and below cursor
	sidescrolloff = 8, -- minimal number of screen columns to keep left/right of cursor
	termguicolors = true, -- Enables 24-bit RGB color in the TUI
	foldenable = true,
	foldlevelstart = 99, -- start with all folds open
	background = "dark", -- colorschemes that can be light or dark will be made dark
	foldmethod = "indent", -- fallback; nvim-ufo overrides to treesitter+indent
	fillchars = {
		eob = " ",
		fold = " ",
		foldopen = "▾",
		foldsep = " ",
		foldclose = "▸",
		lastline = " ",
	}, -- make EndOfBuffer invisible
	foldcolumn = "1",
	ruler = false,
	list = true,
	listchars = "tab:  ,trail:¤,space: ",
}

local global = {
	mkdp_auto_close = false, -- Don't Exit Preview When Switching Buffers
	mapleader = " ", -- Set mapleader to space
}

local opt = vim.opt
opt.shortmess:append("Ac") -- Disable asking when editing file with swapfile.
opt.whichwrap:append("<,>,[,],h,l")
opt.iskeyword:append("-")
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

set_option(options)
set_global(global)

-- Format on save (synchronous so it completes before write)
vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function()
		if vim.bo.buftype == "" then
			local have_nls = package.loaded["null-ls"]
				and (#require("null-ls.sources").get_available(vim.bo.filetype, "NULL_LS_FORMATTING") > 0)
			pcall(vim.lsp.buf.format, {
				async = false,
				timeout_ms = 3000,
				filter = function(client)
					if have_nls then
						return client.name == "null-ls"
					else
						return client.name ~= "null-ls"
					end
				end,
			})
		end
	end,
})

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
	callback = function()
		if vim.bo.modified and vim.bo.buftype == "" and vim.fn.expand("%") ~= "" then
			vim.cmd("silent! write")
		end
	end,
})

-- Auto-reload files changed externally (git checkout, etc.)
vim.o.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
	callback = function()
		if vim.bo.buftype == "" then
			vim.cmd("silent! checktime")
		end
	end,
})
