local command = vim.api.nvim_create_user_command

local function reload_core()
	for name, _ in pairs(package.loaded) do
		if name:match("^core") then
			package.loaded[name] = nil
		end
	end
	local ok, err = pcall(dofile, vim.env.MYVIMRC)
	if not ok then
		vim.notify("Reload failed: " .. tostring(err), vim.log.levels.ERROR)
	end
end

local function format_code()
	return vim.lsp.buf.format({
		async = true,
		filter = function(client)
			local have_nls = package.loaded["null-ls"]
				and (
					#require("null-ls.sources").get_available(
						vim.bo[vim.api.nvim_get_current_buf()].filetype,
						"NULL_LS_FORMATTING"
					) > 0
				)

			if have_nls then
				return client.name == "null-ls"
			else
				return client.name ~= "null-ls"
			end
		end,
	})
end

function _G.set_keymaps(keymaps, mode)
	for keymap, value in pairs(keymaps) do
		local opt = value.opt or {}
		if not value.opt then
			if mode == "c" then
				opt = { expr = true }
			else
				opt = { silent = true }
			end
		end
		opt.desc = value.desc or ""
		vim.keymap.set(mode, keymap, value.cmd, opt)
	end
end

function _G.set_option(options)
	for name, value in pairs(options) do
		vim.opt[name] = value
	end
end

function _G.set_global(globals)
	for name, value in pairs(globals) do
		vim.g[name] = value
	end
end

local function update_config()
	local config_dir = vim.fn.stdpath("config")
	vim.fn.jobstart("git -C " .. config_dir .. " pull --ff-only", {
		on_exit = function(_, exit_code)
			vim.schedule(function()
				if exit_code == 0 then
					vim.notify("Config updated successfully", vim.log.levels.INFO, { title = "Config Update" })
				else
					vim.notify("Config update failed", vim.log.levels.ERROR, { title = "Config Update" })
				end
			end)
		end,
	})
end

command("Format", format_code, { desc = "Code Format" })

command("Reload", function()
	if vim.bo.buftype == "" then
		reload_core()
		vim.notify("Core Reload Done", vim.log.levels.INFO, { title = "Core Reload" })
	else
		vim.notify("Not available in this window/buffer", vim.log.levels.INFO, { title = "Configuration Reload" })
	end
end, { desc = "Core Reload" })

command("Update", update_config, { desc = "Configuration Update" })

command("LuaSnipEdit", function()
	require("luasnip.loaders").edit_snippet_files()
end, { desc = "Edit the available snippets in the filetype" })
