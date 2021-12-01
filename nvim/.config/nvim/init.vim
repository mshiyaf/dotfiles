"{{{ General
"-------------------------------------------------------------------------------

" init autocmd
autocmd!
" set script encoding
scriptencoding utf-8
" stop loading config if it's on tiny or small
if !1 | finish | endif
" enable syntax highlighting
syntax enable
" Turn off paste mode when leaving insert
autocmd InsertLeave * set nopaste

let g:netrw_banner=0
augroup netrw_mapping
    autocmd!
    autocmd filetype netrw call NetrwMapping()
augroup END

function! NetrwMapping()
    nmap <buffer> l <CR>
    nmap <buffer> h -<esc>
endfunction

"}}}

"{{{ File Types
"-------------------------------------------------------------------------------

" JavaScript
au BufNewFile,BufRead *.es6 setf javascript
" JavaScript React
au BufNewFile,BufRead *.jsx setf javascript.jsx
" TypeScript
au BufNewFile,BufRead *.tsx setf typescript.tsx
" Markdown
au BufNewFile,BufRead *.md set filetype=markdown
" Flow
au BufNewFile,BufRead *.flow set filetype=javascript

autocmd FileType coffee setlocal shiftwidth=2 tabstop=2
autocmd FileType ruby setlocal shiftwidth=2 tabstop=2
autocmd FileType yaml setlocal shiftwidth=2 tabstop=2

" filetype plugin indent on
filetype indent on

"}}}

"{{{ Imports
"-------------------------------------------------------------------------------

runtime ./plug.vim
runtime ./maps.vim

"}}}

"{{{" Extras
" ------------------------------------------------------------------------------

set exrc

"}}}

" vim: set foldmethod=marker foldlevel=0:
