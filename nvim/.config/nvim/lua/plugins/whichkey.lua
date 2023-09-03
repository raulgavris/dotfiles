return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 300
		local wk = require("which-key")
		local keymaps = require("core.keymaps")
		for mode, keys in pairs(keymaps) do
			local convertedMappings = {}
			local whichKeyMode = {
				normal_mode = "n",
				insert_mode = "i",
				visual_mode = "v",
				command_mode = "c",
				terminal_mode = "t",
				-- visual_block_mode = "b", -- Add or adjust according to your needs
			}

			for key, values in pairs(keys) do
				convertedMappings[key] = { values.cmd, values.desc }
			end

			if whichKeyMode[mode] then
				wk.register(convertedMappings, {
					mode = whichKeyMode[mode],
				})
			else
				print("Warning: Unknown mode " .. mode)
			end
		end
	end,
	opts = {},
}
