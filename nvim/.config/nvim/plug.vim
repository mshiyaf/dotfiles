" Plugins "{{{
" ------------------------------------------------------------------------
call plug#begin('~/.vim/plugged')

Plug 'ambv/black'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'junegunn/gv.vim'
Plug 'tpope/vim-commentary'
Plug 'puremourning/vimspector'
Plug 'szw/vim-maximizer'
Plug 'mbbill/undotree'
Plug 'neovim/nvim-lspconfig'
Plug 'hoob3rt/lualine.nvim'
Plug 'tami5/lspsaga.nvim'
Plug 'folke/lsp-colors.nvim'
Plug 'gruvbox-community/gruvbox'
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
Plug 'sbdchd/neoformat'
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
Plug 'tpope/vim-vinegar'
Plug 'darrikonn/vim-gofmt', { 'do': ':GoUpdateBinaries' }
Plug 'junegunn/goyo.vim'
" Plug 'github/copilot.vim'
Plug 'mattn/emmet-vim'
Plug 'jwalton512/vim-blade'
Plug 'ThePrimeagen/git-worktree.nvim'
Plug 'windwp/nvim-autopairs'
" Plug 'windwp/nvim-ts-autotag'
Plug 'L3MON4D3/LuaSnip'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'rafamadriz/friendly-snippets'

Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'

Plug 'onsails/lspkind-nvim'
Plug 'dkarter/bullets.vim'

Plug 'williamboman/mason.nvim'
call plug#end()

"}}}

