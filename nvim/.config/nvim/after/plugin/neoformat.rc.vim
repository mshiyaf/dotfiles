" augroup fmt
"   autocmd!
"   au BufWritePre * try | undojoin | Neoformat | catch /^Vim\%((\a\+)\)\=:E790/ | finally | silent Neoformat | endtry
" augroup END
augroup fmt
  autocmd!
  autocmd BufWritePre * undojoin | Neoformat
augroup END

" augroup FormatAutogroup
"   autocmd!
"   autocmd BufWritePost *.js,*.ts,*.rs,*.lua,*.py FormatWrite
" augroup END

" lua << EOF


" require('formatter').setup({
"   filetype = {
"     sh = {
"         -- Shell Script Formatter
"        function()
"          return {
"            exe = "shfmt",
"            args = { "-i", 2 },
"            stdin = true,
"          }
"        end,
"    }
"   }
" })

" function format_prettier()
"    return {
"        exe = "prettier",
"        args = {"--stdin-filepath", vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)), '--single-quote'},
"        stdin = true
"    }
" end

" require("formatter").setup(
" {
"     logging = true,
"     filetype = {
"       typescriptreact = {
"         -- prettier
"            format_prettier
"       },
"       typescript = {
"         -- prettier
"            format_prettier
"       },
"       javascript = {
"         -- prettier
"            format_prettier
"       },
"       javascriptreact = {
"         -- prettier
"            format_prettier
"       },
"       json = {
"         -- prettier
"            format_prettier
"       },
"       lua = {
"         -- luafmt
"         function()
"           return {
"             exe = "luafmt",
"             args = {"--indent-count", 2, "--stdin"},
"             stdin = true
"           }
"         end
"       }
"     }
"   }
" )

" EOF

