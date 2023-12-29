return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = function()
			pcall(require("nvim-treesitter.install").update({ with_sync = true }))
		end,
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			"JoosepAlviste/nvim-ts-context-commentstring",
		},
		config = function()
			local configs = require("nvim-treesitter.configs")

			configs.setup({
				highlight = {
					enable = true,
					disable = {},
				},
				indent = {
					enable = true,
					disable = {},
				},
				ensure_installed = {
					"vimdoc",
					"tsx",
					"javascript",
					"typescript",
					"toml",
					"fish",
					"php",
					"json",
					"yaml",
					"css",
					"html",
					"lua",
					"sql",
					"markdown",
					"markdown_inline",
				},
				autotag = {
					enable = true,
				},
			})

			local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
			parser_config.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }
		end,
	},
	{ "nvim-treesitter/playground" },
}
