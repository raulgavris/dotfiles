return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local lualine = require("lualine")
		local lazy_status = require("lazy.status") -- to configure lazy pending updates count

		local colors = {
			blue = "#458588",
			green = "#98971a",
			violet = "#b16286",
			yellow = "#d79921",
			red = "#cc241d",
			fg = "#ebdbb2",
			bg = "#282828",
			inactive_bg = "#3d302f",
		}

		local my_lualine_theme = {
			normal = {
				a = {
					bg = colors.blue,
					fg = colors.bg,
					gui = "bold",
				},
				b = {
					bg = colors.bg,
					fg = colors.fg,
				},
				c = {
					bg = colors.bg,
					fg = colors.fg,
				},
			},
			insert = {
				a = {
					bg = colors.green,
					fg = colors.bg,
					gui = "bold",
				},
				b = {
					bg = colors.bg,
					fg = colors.fg,
				},
				c = {
					bg = colors.bg,
					fg = colors.fg,
				},
			},
			visual = {
				a = {
					bg = colors.violet,
					fg = colors.bg,
					gui = "bold",
				},
				b = {
					bg = colors.bg,
					fg = colors.fg,
				},
				c = {
					bg = colors.bg,
					fg = colors.fg,
				},
			},
			command = {
				a = {
					bg = colors.yellow,
					fg = colors.bg,
					gui = "bold",
				},
				b = {
					bg = colors.bg,
					fg = colors.fg,
				},
				c = {
					bg = colors.bg,
					fg = colors.fg,
				},
			},
			replace = {
				a = {
					bg = colors.red,
					fg = colors.bg,
					gui = "bold",
				},
				b = {
					bg = colors.bg,
					fg = colors.fg,
				},
				c = {
					bg = colors.bg,
					fg = colors.fg,
				},
			},
			inactive = {
				a = {
					bg = colors.inactive_bg,
					fg = colors.semilightgray,
					gui = "bold",
				},
				b = {
					bg = colors.inactive_bg,
					fg = colors.semilightgray,
				},
				c = {
					bg = colors.inactive_bg,
					fg = colors.semilightgray,
				},
			},
		}

		-- configure lualine with modified theme
		lualine.setup({
			options = {
				theme = my_lualine_theme,
			},
			sections = {
				lualine_x = {
					{
						lazy_status.updates,
						cond = lazy_status.has_updates,
						color = {
							fg = "#ff9e64",
						},
					},
					{ "encoding" },
					{ "fileformat" },
					{ "filetype" },
				},
			},
		})
	end,
}
