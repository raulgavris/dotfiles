if vim.g.vscode then
	require("core.options")
else
	vim.g.loaded_netrw = 1
	vim.g.loaded_netrwPlugin = 1

	local name = "onedark"

	require("core")
	require("pluginsloader")

	-- Check for theme configuration
	-- Theme configs are can be found on lua/plugins/theme
	pcall(require, "plugins.theme." .. name)

	-- Set the theme
	vim.cmd.colorscheme(name)
end
