return {
	"nvim-lualine/lualine.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		local c = {
			black = 0,
			red = 1,
			green = 2,
			yellow = 3,
			blue = 4,
			magenta = 5,
			cyan = 6,
			white = 7,
			bright_black = 8,
		}

		local theme = {
			normal = {
				a = { fg = c.black, bg = c.cyan, gui = "bold" },
				b = { fg = c.cyan, bg = c.bright_black },
				c = { fg = c.cyan, bg = c.black },
			},
			insert = {
				a = { fg = c.black, bg = c.green, gui = "bold" },
				b = { fg = c.cyan, bg = c.bright_black },
				c = { fg = c.cyan, bg = c.black },
			},
			visual = {
				a = { fg = c.black, bg = c.magenta, gui = "bold" },
				b = { fg = c.cyan, bg = c.bright_black },
				c = { fg = c.cyan, bg = c.black },
			},
			command = {
				a = { fg = c.black, bg = c.yellow, gui = "bold" },
				b = { fg = c.cyan, bg = c.bright_black },
				c = { fg = c.cyan, bg = c.black },
			},
			replace = {
				a = { fg = c.black, bg = c.red, gui = "bold" },
				b = { fg = c.cyan, bg = c.bright_black },
				c = { fg = c.cyan, bg = c.black },
			},
			inactive = {
				a = { fg = c.bright_black, bg = c.black },
				b = { fg = c.bright_black, bg = c.black },
				c = { fg = c.bright_black, bg = c.black },
			},
		}

		require("lualine").setup({
			options = {
				theme = theme,
				component_separators = "",
				section_separators = "",
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch" },
				lualine_c = { "filename" },
				lualine_x = { "filetype", "fileformat", "encoding" },
				lualine_y = { "location" },
				lualine_z = { "progress" },
			},
		})
	end,
}
