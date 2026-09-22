local M = {}

-- Workspace config files are stored here (JSON, like VS Code .code-workspace files)
-- Not tracked in git — machine-specific
M.config_dir = vim.fn.stdpath("data") .. "/workspaces"
M.symlink_dir = vim.fn.stdpath("data") .. "/workspace-roots"

-- Internal state
M.active_name = nil
M.active_dirs = nil

--- Expand ~ in paths
local function expand(path)
	return vim.fn.expand(path)
end

--- Ensure config directory exists
local function ensure_config_dir()
	vim.fn.mkdir(M.config_dir, "p")
end

--- Get workspace file path
local function ws_file(name)
	return M.config_dir .. "/" .. name .. ".json"
end

--- Read a workspace config file
local function read_workspace(name)
	local path = ws_file(name)
	local ok, content = pcall(vim.fn.readfile, path)
	if not ok then
		return nil
	end
	local json_ok, data = pcall(vim.json.decode, table.concat(content, "\n"))
	if not json_ok then
		vim.notify("Invalid workspace file: " .. path, vim.log.levels.ERROR)
		return nil
	end
	if not data or type(data.folders) ~= "table" then
		vim.notify("Workspace file missing 'folders' array: " .. path, vim.log.levels.ERROR)
		return nil
	end
	return data
end

--- Write a workspace config file
local function write_workspace(name, data)
	ensure_config_dir()
	local json = vim.json.encode(data)
	-- Pretty print the JSON
	local formatted = json
		:gsub("%[", "[\n  ")
		:gsub("%]", "\n]")
		:gsub('","', '",\n  "')
	vim.fn.writefile({ formatted }, ws_file(name))
end

--- List all workspace names
function M.list()
	ensure_config_dir()
	local files = vim.fn.glob(M.config_dir .. "/*.json", false, true)
	local names = {}
	for _, file in ipairs(files) do
		local name = vim.fn.fnamemodify(file, ":t:r")
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

--- Get folders for a workspace
local function get_folders(name)
	local data = read_workspace(name)
	if not data or not data.folders then
		return nil
	end
	return data.folders
end

--- Create workspace directory with symlinks to all repos
local function setup_symlink_dir(name, dirs)
	local ws_dir = M.symlink_dir .. "/" .. name
	vim.fn.delete(ws_dir, "rf")
	vim.fn.mkdir(ws_dir, "p")

	for _, dir in ipairs(dirs) do
		local expanded = expand(dir)
		local basename = vim.fn.fnamemodify(expanded, ":t")
		local link = ws_dir .. "/" .. basename
		-- Handle duplicate basenames by appending parent dir name
		if vim.uv.fs_stat(link) then
			local parent = vim.fn.fnamemodify(expanded, ":h:t")
			link = ws_dir .. "/" .. parent .. "-" .. basename
		end
		local ok, err = vim.uv.fs_symlink(expanded, link)
		if not ok then
			vim.notify("Symlink failed for " .. expanded .. ": " .. tostring(err), vim.log.levels.WARN)
		end
	end

	return ws_dir
end

--- Get expanded dirs for active workspace
function M.get_dirs()
	if not M.active_dirs then
		return nil
	end
	local expanded = {}
	for _, dir in ipairs(M.active_dirs) do
		table.insert(expanded, expand(dir))
	end
	return expanded
end

--- Open a workspace by name
function M.open(name)
	local folders = get_folders(name)
	if not folders or #folders == 0 then
		vim.notify("Workspace '" .. name .. "' has no folders", vim.log.levels.ERROR)
		return
	end

	-- Create symlink directory
	local ws_dir = setup_symlink_dir(name, folders)

	-- Close all buffers from previous workspace
	vim.cmd("%bdelete!")

	-- Change working directory to workspace root
	vim.cmd("cd " .. vim.fn.fnameescape(ws_dir))

	-- Store active workspace
	M.active_name = name
	M.active_dirs = folders

	-- Reveal in Neo-tree
	vim.cmd("Neotree reveal")

	local repo_names = {}
	for _, dir in ipairs(folders) do
		table.insert(repo_names, vim.fn.fnamemodify(dir, ":t"))
	end
	vim.notify("Workspace: " .. name .. "\n  " .. table.concat(repo_names, "\n  "), vim.log.levels.INFO)
end

--- Select workspace via picker
function M.select()
	local names = M.list()

	if #names == 0 then
		vim.notify(
			"No workspaces found.\nCreate one with :WorkspaceCreate <name>\nor add folders with :WorkspaceAdd <name> <path>",
			vim.log.levels.WARN
		)
		return
	end

	vim.ui.select(names, {
		prompt = "Select Workspace:",
		format_item = function(name)
			local folders = get_folders(name)
			if not folders then
				return name
			end
			local repos = {}
			for _, dir in ipairs(folders) do
				table.insert(repos, vim.fn.fnamemodify(dir, ":t"))
			end
			return name .. "  (" .. table.concat(repos, ", ") .. ")"
		end,
	}, function(choice)
		if choice then
			M.open(choice)
		end
	end)
end

--- Create a new workspace
function M.create(name)
	if vim.fn.filereadable(ws_file(name)) == 1 then
		vim.notify("Workspace '" .. name .. "' already exists", vim.log.levels.WARN)
		return
	end
	write_workspace(name, { folders = {} })
	vim.notify("Created workspace: " .. name .. "\nAdd folders with :WorkspaceAdd " .. name .. " <path>", vim.log.levels.INFO)
end

--- Add a folder to a workspace
function M.add_folder(name, path)
	local data = read_workspace(name)
	if not data then
		vim.notify("Workspace '" .. name .. "' not found. Create it first with :WorkspaceCreate " .. name, vim.log.levels.ERROR)
		return
	end

	local expanded = expand(path)
	-- Verify directory exists
	if vim.fn.isdirectory(expanded) == 0 then
		vim.notify("Directory not found: " .. expanded, vim.log.levels.ERROR)
		return
	end

	-- Check for duplicates
	for _, existing in ipairs(data.folders) do
		if expand(existing) == expanded then
			vim.notify("Already in workspace: " .. expanded, vim.log.levels.WARN)
			return
		end
	end

	table.insert(data.folders, expanded)
	write_workspace(name, data)
	vim.notify("Added to " .. name .. ": " .. vim.fn.fnamemodify(expanded, ":t"), vim.log.levels.INFO)

	-- If this workspace is active, re-open to pick up the new folder
	if M.active_name == name then
		M.open(name)
	end
end

--- Remove a folder from a workspace
function M.remove_folder(name)
	local data = read_workspace(name)
	if not data or not data.folders or #data.folders == 0 then
		vim.notify("Workspace '" .. name .. "' has no folders", vim.log.levels.WARN)
		return
	end

	vim.ui.select(data.folders, {
		prompt = "Remove folder from " .. name .. ":",
		format_item = function(dir)
			return vim.fn.fnamemodify(dir, ":t") .. "  (" .. dir .. ")"
		end,
	}, function(choice)
		if choice then
			local new_folders = {}
			for _, dir in ipairs(data.folders) do
				if dir ~= choice then
					table.insert(new_folders, dir)
				end
			end
			data.folders = new_folders
			write_workspace(name, data)
			vim.notify("Removed: " .. vim.fn.fnamemodify(choice, ":t"), vim.log.levels.INFO)
			if M.active_name == name then
				M.open(name)
			end
		end
	end)
end

--- Delete a workspace
function M.delete(name)
	local path = ws_file(name)
	if vim.fn.filereadable(path) == 0 then
		vim.notify("Workspace '" .. name .. "' not found", vim.log.levels.ERROR)
		return
	end
	vim.fn.delete(path)
	-- Clean up symlink dir
	vim.fn.delete(M.symlink_dir .. "/" .. name, "rf")
	if M.active_name == name then
		M.active_name = nil
		M.active_dirs = nil
	end
	vim.notify("Deleted workspace: " .. name, vim.log.levels.INFO)
end

--- Edit workspace file directly
function M.edit(name)
	local path = ws_file(name)
	if vim.fn.filereadable(path) == 0 then
		vim.notify("Workspace '" .. name .. "' not found", vim.log.levels.ERROR)
		return
	end
	vim.cmd("edit " .. vim.fn.fnameescape(path))
end

--- Find files across all workspace dirs (or cwd if no workspace)
function M.find_files()
	local dirs = M.get_dirs()
	if dirs then
		require("telescope.builtin").find_files({ search_dirs = dirs })
	else
		require("telescope.builtin").find_files()
	end
end

--- Live grep across all workspace dirs (or cwd if no workspace)
function M.live_grep()
	local dirs = M.get_dirs()
	if dirs then
		require("telescope.builtin").live_grep({ search_dirs = dirs })
	else
		require("telescope.builtin").live_grep()
	end
end

--- Grep string across all workspace dirs
function M.grep_string()
	local dirs = M.get_dirs()
	if dirs then
		require("telescope.builtin").grep_string({ search_dirs = dirs })
	else
		require("telescope.builtin").grep_string()
	end
end

-- Completion helper: list workspace names
local function complete_workspace_names()
	return M.list()
end

-- Commands
vim.api.nvim_create_user_command("WorkspaceSelect", function()
	M.select()
end, { desc = "Select and open a workspace" })

vim.api.nvim_create_user_command("WorkspaceCreate", function(opts)
	M.create(opts.args)
end, { nargs = 1, desc = "Create a new workspace" })

vim.api.nvim_create_user_command("WorkspaceOpen", function(opts)
	M.open(opts.args)
end, { nargs = 1, desc = "Open a workspace by name", complete = complete_workspace_names })

vim.api.nvim_create_user_command("WorkspaceAdd", function(opts)
	local args = vim.split(opts.args, " ", { trimempty = true })
	if #args < 2 then
		-- If workspace is active, add to it; otherwise require name
		if M.active_name and #args == 1 then
			M.add_folder(M.active_name, args[1])
		else
			vim.notify("Usage: :WorkspaceAdd <workspace> <path>", vim.log.levels.ERROR)
		end
		return
	end
	M.add_folder(args[1], table.concat(args, " ", 2))
end, {
	nargs = "+",
	desc = "Add a folder to a workspace",
	complete = function(arg_lead, cmd_line)
		local args = vim.split(cmd_line, " ", { trimempty = true })
		if #args <= 2 then
			return complete_workspace_names()
		end
		return vim.fn.getcompletion(arg_lead, "dir")
	end,
})

vim.api.nvim_create_user_command("WorkspaceRemove", function(opts)
	local name = opts.args ~= "" and opts.args or M.active_name
	if not name then
		vim.notify("Usage: :WorkspaceRemove <workspace> or activate one first", vim.log.levels.ERROR)
		return
	end
	M.remove_folder(name)
end, { nargs = "?", desc = "Remove a folder from a workspace", complete = complete_workspace_names })

vim.api.nvim_create_user_command("WorkspaceDelete", function(opts)
	M.delete(opts.args)
end, { nargs = 1, desc = "Delete a workspace", complete = complete_workspace_names })

vim.api.nvim_create_user_command("WorkspaceEdit", function(opts)
	local name = opts.args ~= "" and opts.args or M.active_name
	if not name then
		vim.notify("Usage: :WorkspaceEdit <workspace>", vim.log.levels.ERROR)
		return
	end
	M.edit(name)
end, { nargs = "?", desc = "Edit workspace JSON file", complete = complete_workspace_names })

vim.api.nvim_create_user_command("WorkspaceClose", function()
	if M.active_name then
		local name = M.active_name
		M.active_name = nil
		M.active_dirs = nil
		vim.notify("Closed workspace: " .. name, vim.log.levels.INFO)
	end
end, { desc = "Close active workspace" })

vim.api.nvim_create_user_command("WorkspaceInfo", function()
	if M.active_name then
		local dirs = M.get_dirs()
		local lines = { "Workspace: " .. M.active_name }
		for _, dir in ipairs(dirs) do
			table.insert(lines, "  " .. dir)
		end
		lines[#lines + 1] = "Config: " .. ws_file(M.active_name)
		vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
	else
		vim.notify("No workspace active", vim.log.levels.INFO)
	end
end, { desc = "Show active workspace info" })

-- Quick add: add current working directory to active workspace
vim.api.nvim_create_user_command("WorkspaceAddCwd", function()
	if not M.active_name then
		vim.notify("No workspace active. Use :WorkspaceSelect first", vim.log.levels.WARN)
		return
	end
	M.add_folder(M.active_name, vim.fn.getcwd())
end, { desc = "Add current directory to active workspace" })

return M
