if vim.g.vscode then
	require("core.options")
else
	vim.g.loaded_netrw = 1
	vim.g.loaded_netrwPlugin = 1

	local name = "onedark"

	require("core")
	require("pluginsloader")

	-- Theme configs in lua/plugins/theme/
	local ok, err = pcall(require, "plugins.theme." .. name)
	if not ok then
		vim.notify("Theme config failed: " .. tostring(err), vim.log.levels.WARN)
	end

	vim.cmd.colorscheme(name)
end
