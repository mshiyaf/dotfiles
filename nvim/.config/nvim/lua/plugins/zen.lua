return {
	"folke/zen-mode.nvim",
	opts = {
		vim.keymap.set("n", "<C-w>o", "<cmd>ZenMode<cr>", { silent = true }),
	},
}
