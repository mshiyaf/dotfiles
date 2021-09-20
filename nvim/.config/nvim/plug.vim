" Plugins "{{{
" ------------------------------------------------------------------------
call plug#begin('~/.vim/plugged')

Plug 'ambv/black'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'tpope/vim-commentary'
Plug 'puremourning/vimspector'
Plug 'szw/vim-maximizer'
Plug 'mbbill/undotree'
Plug 'hoob3rt/lualine.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'glepnir/lspsaga.nvim'
Plug 'folke/lsp-colors.nvim'
Plug 'gruvbox-community/gruvbox'
Plug 'hoob3rt/lualine.nvim'
Plug 'sbdchd/neoformat'
Plug 'hrsh7th/nvim-compe'
Plug 'L3MON4D3/LuaSnip'
Plug 'rafamadriz/friendly-snippets'
Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
Plug 'tpope/vim-vinegar'
call plug#end()
"}}}

" vim: set foldmethod=marker foldlevel=0:
