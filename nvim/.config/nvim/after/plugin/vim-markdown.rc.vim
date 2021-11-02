" let g:vim_markdown_conceal = 1
let g:vim_markdown_folding_disabled = 1


" Goyo
function s:goyo_enter()
  if exists('$TMUX')
    silent !tmux set status off
  endif
endfunction

function! s:goyo_leave()
 hi Normal guibg=NONE ctermbg=NONE
 if exists('$TMUX')
    silent !tmux set status on
 endif        
endfunction

autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()
