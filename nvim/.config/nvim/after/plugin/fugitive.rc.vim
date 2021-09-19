"fugitive status line
if !exists('*fugitive#statusline')
  set statusline=%f\ %m%r%h%w%y%{'['.(&fenc!=''?&fenc:&enc).':'.&ff.']'}[l%l/%l,c%03v]
  set statusline+=%=
  set statusline+=%{fugitive#statusline()}
endif

cnoreabbrev g Git
cnoreabbrev gopen GBrowse

autocmd BufRead COMMIT_EDITMSG set spell
