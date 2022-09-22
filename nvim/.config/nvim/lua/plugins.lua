local status, packer = pcall(require, "packer")
if not status then
	print("Packer is not installed")
	return
end

vim.cmd([[packadd packer.nvim]])

packer.startup(function(use)
	use("wbthomason/packer.nvim")
	use("folke/tokyonight.nvim")
	use("nvim-lualine/lualine.nvim") -- Statusline

	use("nvim-lua/plenary.nvim") -- Common utilities
	use("nvim-lua/popup.nvim") -- Common utilities
	use("onsails/lspkind-nvim") -- vscode-like pictograms

	use("hrsh7th/nvim-cmp") -- Completion
	use("hrsh7th/cmp-buffer") -- nvim-cmp source for buffer words
	use("hrsh7th/cmp-path") -- nvim-cmp source for filepath path
	use("hrsh7th/cmp-cmdline") -- nvim-cmp source for command line
	use("hrsh7th/cmp-nvim-lsp") -- nvim-cmp source for neovim's built-in LSP

	use("saadparwaiz1/cmp_luasnip")
	use("L3MON4D3/LuaSnip")

	use("neovim/nvim-lspconfig") -- LSP
	use("jose-elias-alvarez/null-ls.nvim") -- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua
	use("MunifTanjim/prettier.nvim") -- Prettier plugin for Neovim's built-in LSP client
	use("williamboman/mason.nvim")
	use("williamboman/mason-lspconfig.nvim")

	use("glepnir/lspsaga.nvim") -- LSP UIs
	use({
		"nvim-treesitter/nvim-treesitter",
		run = ":TSUpdate",
	})
	use("kyazdani42/nvim-web-devicons") -- File icons
	use("nvim-telescope/telescope.nvim")
	use("nvim-telescope/telescope-file-browser.nvim")
	use("windwp/nvim-autopairs")
	use("windwp/nvim-ts-autotag")
	use("folke/zen-mode.nvim")
	--  use({
	--    "iamcco/markdown-preview.nvim",
	--    run = function() vim.fn["mkdp#util#install"]() end,
	--  })
	use("akinsho/nvim-bufferline.lua")

	use("lewis6991/gitsigns.nvim")
	use("tpope/vim-fugitive")

	use("tpope/vim-commentary") -- Comment lines
	use("szw/vim-maximizer") -- Toggle window maximization

	-- use("tpope/vinegar")
	use("akinsho/toggleterm.nvim")
	use("ThePrimeagen/git-worktree.nvim") -- Git worktree implementation in telescope
	use("mbbill/undotree")

	use("mong8se/actually.nvim")

	use({
		"anuvyklack/windows.nvim",
		requires = {
			"anuvyklack/middleclass",
			-- "anuvyklack/animation.nvim",
		},
		config = function()
			vim.o.winwidth = 10
			vim.o.winminwidth = 10
			vim.o.equalalways = false
			require("windows").setup()
		end,
	})

	use("lukas-reineke/indent-blankline.nvim")
	-- use({
	-- 	"folke/which-key.nvim",
	-- 	config = function()
	-- 		require("which-key").setup({})
	-- 	end,
	-- })
end)
