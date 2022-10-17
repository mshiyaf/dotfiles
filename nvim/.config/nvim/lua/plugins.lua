local status, packer = pcall(require, "packer")
if not status then
	print("Packer is not installed")
	return
end

vim.cmd([[packadd packer.nvim]])

packer.startup(function(use)
	use("wbthomason/packer.nvim")
	use("lewis6991/impatient.nvim") -- Load lua modules faster

	use("folke/tokyonight.nvim")
	use("nvim-lualine/lualine.nvim") -- Statusline
	use("tpope/vim-vinegar")

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
	use("rafamadriz/friendly-snippets")

	use("neovim/nvim-lspconfig") -- LSP
	use("jose-elias-alvarez/null-ls.nvim") -- Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua
	use("williamboman/mason.nvim")
	use("williamboman/mason-lspconfig.nvim")

	use("glepnir/lspsaga.nvim") -- LSP UIs
	use({
		"nvim-treesitter/nvim-treesitter",
		run = ":TSUpdate",
	})
	use("nvim-treesitter/playground")
	use("kyazdani42/nvim-web-devicons") -- File icons
	use("nvim-telescope/telescope.nvim")
	use("windwp/nvim-autopairs")
	use("windwp/nvim-ts-autotag")
	use("folke/zen-mode.nvim")

	use("akinsho/nvim-bufferline.lua")

	-- Git
	use("lewis6991/gitsigns.nvim")
	use("tpope/vim-fugitive")
	use("ThePrimeagen/git-worktree.nvim")
	use("sindrets/diffview.nvim")

	use("szw/vim-maximizer") -- Toggle window maximization

	use("akinsho/toggleterm.nvim")
	use("mbbill/undotree")
	use("mong8se/actually.nvim")

	use("lukas-reineke/indent-blankline.nvim")

	use({
		"goolord/alpha-nvim",
		config = function()
			require("alpha").setup(require("alpha.themes.startify").config)
		end,
	})

	-- use("dstein64/vim-startuptime")
	use("RRethy/vim-illuminate")
	use("jwalton512/vim-blade")
	use("nvim-telescope/telescope-ui-select.nvim")
	use({
		"SmiteshP/nvim-navic",
		requires = "neovim/nvim-lspconfig",
	})
	use({
		"kylechui/nvim-surround",
		tag = "*", -- Use for stability; omit to use `main` branch for the latest features
		config = function()
			require("nvim-surround").setup({
				-- Configuration here, or leave empty to use defaults
			})
		end,
	})
	-- use("simrat39/inlay-hints.nvim")
	-- use({
	-- 	"folke/noice.nvim",
	-- 	event = "VimEnter",
	-- 	requires = {
	-- 		-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
	-- 		"MunifTanjim/nui.nvim",
	-- 		"rcarriga/nvim-notify",
	-- 	},
	-- })
	use("numToStr/Comment.nvim")
	use("JoosepAlviste/nvim-ts-context-commentstring")

	use({
		"iamcco/markdown-preview.nvim",
		run = function()
			vim.fn["mkdp#util#install"]()
		end,
	})
end)
