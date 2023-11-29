return {
	{
		"navarasu/onedark.nvim",
		config = function()
			require("onedark").setup({
				style = "warmer",
				transparent = false,
			})
			vim.cmd([[colorscheme onedark]])
		end,
	},
}
