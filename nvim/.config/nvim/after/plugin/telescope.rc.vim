" Find files using Telescope command-line sugar.
nnoremap <leader>f <cmd>Telescope find_files<cr>
nnoremap <C-p> <cmd>Telescope git_files<cr>
nnoremap <leader>g <cmd>Telescope live_grep<cr>
nnoremap <leader>b <cmd>Telescope buffers<cr>
nnoremap <leader>h <cmd>Telescope help_tags<cr>
nnoremap <leader>vt <cmd>Telescope treesitter<cr>
nnoremap <leader>vm <cmd>Telescope man_pages<cr>
nnoremap <leader>vb <cmd>Telescope git_bcommits<cr>
nnoremap <leader>vc <cmd>Telescope git_commits<cr>
nnoremap <leader>rr <cmd>Telescope lsp_references<cr>
nnoremap <leader>; :lua require('telescope').extensions.git_worktree.git_worktrees()<cr>
nnoremap <leader>ww :lua require('telescope').extensions.git_worktree.create_git_worktree()<cr>
