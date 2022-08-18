local Remap = require("keymap")
local nnoremap = Remap.nnoremap
local vnoremap = Remap.vnoremap
local inoremap = Remap.inoremap
local nmap = Remap.nmap

local silent = { silent = true }

-- Change netrw default mappings
-- vim.api.nvim_create_autocmd("filetype", {
--   pattern = "netrw",
--   callback = function()
--     vim.keymap.set('n','l','<CR>',{remap = true, buffer = true})
--     vim.keymap.set('n','h','-<esc>',{remap = true, buffer = true})
--   end
-- })

-- Reload vim config
nnoremap('<Leader><CR>', ':so ~/.config/nvim/init.lua<CR>')

-- Don't yank with x
nnoremap('x', '"_x')
nnoremap('<leader>d', '"_x')

-- Increment/decrement
nnoremap('+', '<C-a>')
nnoremap('_', '<C-x>')

-- Select all
nnoremap('<C-a>', 'gg<S-v>G')
-- Move a line of text using ALT+[jk] or Command+[jk] on mac
nnoremap('<A-j>', 'mz:m+<cr>`z')
nnoremap('<A-k>', 'mz:m-2<cr>`z')
vnoremap('<A-j>', ":m'>+<cr>`<my`>mzgv`yo`z")
vnoremap('<A-k>', ":m'<-2<cr>`>my`<mzgv`yo`z")

-- Save with root permission (not working for now)
--vim.api.nvim_create_user_command('W', 'w !sudo tee > /dev/null %', {})

-- New tab
nnoremap('te', ':tabedit<CR>', silent)

-- Split window
nnoremap('ss', ':split<CR><C-w>w', silent)
nnoremap('sv', ':vsplit<CR><C-w>w', silent)

-- Move window
nnoremap('<Space>j', '<C-w>w')
nnoremap('sh', '<C-w>h')
nnoremap('sk', '<C-w>k')
nnoremap('sj', '<C-w>j')
nnoremap('sl', '<C-w>l')

-- Resize window
nnoremap('<C-w><left>', '<C-w><')
nnoremap('<C-w><right>', '<C-w>>')
nnoremap('<C-w><up>', '<C-w>+')
nnoremap('<C-w><down>', '<C-w>-')
nnoremap('<leader>=', '<C-w>=')
nnoremap('<leader>m', ':MaximizerToggle<CR>', silent)
vnoremap('<leader>m', ':MaximizerToggle<CR>gv', silent)
inoremap('<F3>', '<C-o>:MaximizerToggle<CR>', silent)

-- tmux-sessionizer
nnoremap('<C-f>', ':silent !tmux neww ~/Code/dotfiles/zsh/.config/zsh/tmux-sessionizer.sh<CR>', silent)

-- terminal
nmap('<leader>t', ':terminal<Return>i')

-- undotree
nnoremap('<F4>', ':UndotreeToggle<CR>:UndotreeFocus<CR>')
