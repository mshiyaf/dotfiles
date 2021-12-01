set noerrorbells
set number
set relativenumber
set nocompatible
set fileencodings=utf-8,sjis,euc-jp,latin
set encoding=utf-8
set title
set autoindent
set hlsearch
set showcmd
set cmdheight=1
set laststatus=2
set expandtab
set hidden
set scrolloff=8
set colorcolumn=80
set signcolumn=yes

" history related
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile

" turn on the folding
" set foldmethod=syntax
" set foldcolumn=1
" let javascript_fold=1

"let loaded_matchparen = 1
set shell=zsh
set backupskip=/tmp/*,/private/tmp/*

" incremental substitution (neovim)
if has('nvim')
    set inccommand=split
endif

" Suppress appending <PasteStart> and <PasteEnd> when pasting
set t_BE=
set nosc noru nosm
" Don't redraw while executing macros (good performance config)
set lazyredraw
"set showmatch
" How many tenths of a second to blink when matching brackets
"set mat=2
set incsearch
" Ignore case when searching
set nohlsearch
set ignorecase
set smartcase
" Be smart when using tabs ;)
set smarttab
" indents
set tabstop=2 softtabstop=2
set shiftwidth=2
set ai "Auto indent
set si "Smart indent
set nowrap "No Wrap lines
set backspace=start,eol,indent

" Finding files - Search down into subfolders
set path+=**
" ignore files
set wildignore+=*.pyc
set wildignore+=*_build/*
set wildignore+=**/coverage/*
set wildignore+=**/node_modules/*
set wildignore+=**/android/*
set wildignore+=**/ios/*
set wildignore+=**/.git/*
set wildignore+=*/node_modules/*


" For conceal markers.
if has('conceal')
    set conceallevel=2 concealcursor=niv
endif

" Add asterisks in block comments
set formatoptions+=r

if has("unix")
    let s:uname = system("uname -s")
    " Do Mac stuff
    if s:uname == "Darwin\n"
        " Use OSX clipboard to copy and to paste
        set clipboard+=unnamedplus
        " Copy selected text in visual mode
        "set clipboard+=autoselect
    endif
endif

set suffixesadd=.js,.es,.jsx,.json,.css,.less,.sass,.styl,.php,.py,.md
