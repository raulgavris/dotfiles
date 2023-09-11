local function transformKeymaps(inputKeymaps)
	local outputKeymaps = {}

	for _, mappings in pairs(inputKeymaps) do
		for key, action in pairs(mappings) do
			local item = {}
			item[1] = key

			if type(action.cmd) == "string" then
				item[2] = action.cmd
			elseif type(action.cmd) == "function" then
				item[2] = action.cmd
			end

			item.description = action.desc

			if action.opt then
				item.opts = action.opt
			end

			table.insert(outputKeymaps, item)
		end
	end

	return outputKeymaps
end

local keymaps = require("core.keymaps")
local legendaryKeymaps = transformKeymaps(keymaps)

return {
	"mrjones2014/legendary.nvim",
	-- since legendary.nvim handles all your keymaps/commands,
	-- its recommended to load legendary.nvim before other plugins
	priority = 10000,
	lazy = false,
	-- sqlite is only needed if you want to use frecency sorting
	-- dependencies = { 'kkharji/sqlite.lua' }

	config = function()
		require("legendary").setup({ keymaps = legendaryKeymaps })
	end,
}
