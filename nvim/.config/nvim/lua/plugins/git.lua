return {
	"lewis6991/gitsigns.nvim",
	"tpope/vim-fugitive",
	"tpope/vim-rhubarb",
	"ThePrimeagen/git-worktree.nvim",
	"sindrets/diffview.nvim",
	"github/copilot.vim",
	config = function()
		require("gitsigns").setup({})
		vim.cmd("cnoreabbrev g Git")
		vim.cmd("cnoreabbrev dg DiffviewOpen")
		vim.cmd("cnoreabbrev dc DiffviewClose")
	end,
}
