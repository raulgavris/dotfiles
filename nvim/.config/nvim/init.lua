if vim.g.vscode then
  require "core.options"
else
  local name = "onedark"

  require "core"
  require "pluginsloader"

  -- Check for theme configuration
  -- Theme configs are can be found on lua/plugins/theme
  pcall(require, "plugins.theme." .. name)

  -- Set the theme
  vim.cmd.colorscheme(name)
end
