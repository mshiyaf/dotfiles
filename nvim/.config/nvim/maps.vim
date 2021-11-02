"{{{ General Mappings
""-------------------------------------------------------------------------------

let mapleader=" "
nnoremap <S-C-p> "0p

" Delete without yank
nnoremap <leader>d "_d
nnoremap x "_x

" Increment/decrement
nnoremap + <C-a>
" nnoremap - <C-x>

" Select all
nmap <C-a> gg<S-v>G

" Save with root permission
command! W w !sudo tee > /dev/null %

" Search for selected text, forwards or backwards.
vnoremap <silent> * :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy/<C-R><C-R>=substitute(
  \escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gV:call setreg('"', old_reg, old_regtype)<CR>
vnoremap <silent> # :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy?<C-R><C-R>=substitute(
  \escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gV:call setreg('"', old_reg, old_regtype)<CR>

" save the current file
map! <C-W> <Esc>:w! <cr>

" Move a line of text using ALT+[jk] or Command+[jk] on mac
nmap <A-j> mz:m+<cr>`z
nmap <A-k> mz:m-2<cr>`z
vmap <A-j> :m'>+<cr>`<my`>mzgv`yo`z
vmap <A-k> :m'<-2<cr>`>my`<mzgv`yo`z

" tmux-sessionizer
nnoremap <silent> <C-f> :silent !tmux neww ~/Code/dotfiles/zsh/.config/zsh/tmux-sessionizer.sh<CR>

nnoremap <F5> :UndotreeToggle<CR>:UndotreeFocus<CR>

nmap <leader><C-M> <Plug>BujoAddnormal
nmap <C-BS> <Plug>BujoChecknormal
" imap <C-BS> <Plug>BujoCheckinsert
" imap <C-M> <Plug>BujoAddinsert

" Open explore
map <leader>z :Goyo<CR>
nnoremap <leader>u :UndotreeToggle<CR>:UndotreeFocus<CR>
nnoremap <Leader><CR> :so ~/.config/nvim/init.vim<CR>

"}}}

"{{{ Tabs
"-------------------------------------------------------------------------------

" Open current directory
nmap te :tabedit 
nmap <S-Tab> :tabprev<Return>
" nmap <Tab> :tabnext<Return>

"}}}

"{{{ Windows
"-------------------------------------------------------------------------------

" Split window
nmap ss :split<Return><C-w>w
nmap sv :vsplit<Return><C-w>w

" Move window
nmap <leader>j <C-w>w
map s<left> <C-w>h
map s<up> <C-w>k
map s<down> <C-w>j
map s<right> <C-w>l
map sh <C-w>h
map sk <C-w>k
map sj <C-w>j
map sl <C-w>l

" Resize window
nmap <C-w><left> <C-w><
nmap <C-w><right> <C-w>>
nmap <C-w><up> <C-w>+
nmap <C-w><down> <C-w>-
nnoremap <leader>+ :vertical resize +5<CR>
nnoremap <leader>- :vertical resize -5<CR>
nnoremap <leader>-- :vertical resize -20<CR>
nnoremap <leader>-t :resize -20<CR>
nnoremap <leader>= <C-w>=
nnoremap <silent><leader>m :MaximizerToggle<CR>
vnoremap <silent><leader>m :MaximizerToggle<CR>gv
inoremap <silent><F3> <C-o>:MaximizerToggle<CR>

"}}}

"{{{ Terminal
"-------------------------------------------------------------------------------

" tnoremap <Esc> <C-\><C-n>
nmap <leader>t :terminal<Return>i

"}}}

" vim: set foldmethod=marker foldlevel=0:
