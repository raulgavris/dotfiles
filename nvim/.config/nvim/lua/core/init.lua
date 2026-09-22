-- Silence the `client.supports_method` deprecation warning emitted by several
-- third-party plugins (vim-illuminate, snacks.nvim, trouble.nvim, etc.) on
-- every LSP attach. Remove once those plugins migrate to the colon-form call.
local orig_deprecate = vim.deprecate
vim.deprecate = function(name, ...)
	if name == "client.supports_method" then
		return
	end
	return orig_deprecate(name, ...)
end

require("core.utils")
require("core.keymaps")
require("core.options")
require("core.workspaces")
