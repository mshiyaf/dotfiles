if !exists('g:loaded_lspsaga') | finish | endif

lua << EOF
local saga = require 'lspsaga'

saga.init_lsp_saga {
  error_sign = '',
  warn_sign = '',
  hint_sign = '',
  infor_sign = '',
  border_style = "round",
}

EOF

nnoremap <silent> <C-j> <Cmd>Lspsaga diagnostic_jump_next<CR>
nnoremap <leader>rn <Cmd>Lspsaga rename<CR>
nnoremap <silent> <C-k> <Cmd>Lspsaga hover_doc<CR>
nnoremap <silent><leader>ca <cmd>lua require('lspsaga.codeaction').code_action()<CR>
nnoremap <silent> gh <Cmd>Lspsaga lsp_finder<CR>
