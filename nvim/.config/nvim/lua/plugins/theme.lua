return {
	"catppuccin/nvim",
	name = "catppuccin",
	config = function()
		require("catppuccin").setup({
			flavour = "mocha", -- latte, frappe, macchiato, mocha
			background = { -- :h background
				light = "latte",
				dark = "mocha",
			},
			compile_path = vim.fn.stdpath("cache") .. "/catppuccin",
			transparent_background = true,
			term_colors = true,
			dim_inactive = {
				enabled = true,
				shade = "dark",
				percentage = 0.15,
			},
			styles = {
				comments = { "italic" },
				conditionals = { "italic" },
				loops = {},
				functions = {},
				keywords = { "italic" },
				strings = {},
				variables = {},
				numbers = {},
				booleans = {},
				properties = {},
				types = {},
				operators = {},
			},
			color_overrides = {},
			integrations = {
				cmp = true,
				gitsigns = true,
				nvimtree = true,
				telescope = true,
				treesitter = true,
				-- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
			},
			custom_highlights = function(c)
				local prompt = "#2d3149"
				return {
					TelescopeNormal = {
						bg = c.bg_dark,
						fg = c.fg_dark,
					},
					TelescopeBorder = {
						bg = c.bg_dark,
						fg = c.bg_dark,
					},
					TelescopePromptNormal = {
						bg = prompt,
					},
					TelescopePromptBorder = {
						bg = prompt,
						fg = prompt,
					},
					TelescopePromptTitle = {
						bg = prompt,
						fg = prompt,
					},
					TelescopePreviewTitle = {
						bg = c.bg_dark,
						fg = c.bg_dark,
					},
					TelescopeResultsTitle = {
						bg = c.bg_dark,
						fg = c.bg_dark,
					},
				}
			end,
		})

		vim.cmd([[colorscheme catppuccin]])
	end,
}
