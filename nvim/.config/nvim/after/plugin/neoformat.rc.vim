" augroup fmt
"   autocmd!
"   au BufWritePre * try | undojoin | Neoformat | catch /^Vim\%((\a\+)\)\=:E790/ | finally | silent Neoformat | endtry
" augroup END
" augroup fmt
"     autocmd!
"     autocmd BufWritePre * undojoin | Neoformat
" augroup END

" Enable alignment
let g:neoformat_basic_format_align = 1

" Enable tab to spaces conversion
let g:neoformat_basic_format_retab = 1

" Enable trimmming of trailing whitespace
let g:neoformat_basic_format_trim = 1

let g:neoformat_enabled_javascript = ['prettier']
