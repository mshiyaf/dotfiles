-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1

-- OR setup with some options
require("nvim-tree").setup({
	view = {
		mappings = {
			list = {
				{ key = "-", action = "dir_up" },
				{ key = "h", action = "close_node" },
				{ key = "n", action = "create" },
				{ key = "l", action = "toggle_replace" },
			},
		},
		float = {
			enable = true,
		},
	},
	renderer = {
		icons = {
			glyphs = {
				folder = {
					arrow_closed = "❯",
				},
			},
		},
	},
	actions = {
		open_file = {
			window_picker = {
				enable = false,
			},
		},
	},
})
