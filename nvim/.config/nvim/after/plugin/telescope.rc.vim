" telescope extension for git-worktree
lua << EOF
require("telescope").load_extension("git_worktree")
EOF
" Find files using Telescope command-line sugar.
nnoremap <leader>f <cmd>Telescope find_files<cr>
nnoremap <C-p> <cmd>Telescope git_files<cr>
nnoremap <leader>g <cmd>Telescope live_grep<cr>
nnoremap <leader>b <cmd>Telescope buffers<cr>
nnoremap <leader>h <cmd>Telescope help_tags<cr>
nnoremap <leader>; :lua require('telescope').extensions.git_worktree.git_worktrees()<cr>
" nnoremap <leader>e <cmd>Telescope file_browser<CR>
"

lua << EOF
local Worktree = require("git-worktree")

-- op = Operations.Switch, Operations.Create, Operations.Delete
-- metadata = table of useful values (structure dependent on op)
--      Switch
--          path = path you switched to
--          prev_path = previous worktree path
--      Create
--          path = path where worktree created
--          branch = branch name
--          upstream = upstream remote name
--      Delete
--          path = path where worktree deleted

Worktree.on_tree_change(function(op, metadata)
if op == Worktree.Operations.Switch then
    print("Switched from " .. metadata.prev_path .. " to " .. metadata.path)
end
end)
EOF
