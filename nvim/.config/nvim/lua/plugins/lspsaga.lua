return {
	"glepnir/lspsaga.nvim",
	version = "main",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local saga = require("lspsaga")
		saga.setup({
			server_filetype_map = {
				typescript = "typescript",
			},
			lightbulb = {
				enable = false,
				enable_in_insert = false,
			},
			symbol_in_winbar = {
				folder_level = 1,
				color_mode = false,
			},
		})
		local icons = require("nvim-web-devicons")
		icons.setup({
			-- your personnal icons can go here (to override)
			-- DevIcon will be appended to `name`
			override = {},
			-- globally enable default icons (default to false)
			-- will get overriden by `get_icons` option
			default = true,
		})
	end,
}
