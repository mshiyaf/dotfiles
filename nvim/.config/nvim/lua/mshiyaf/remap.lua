local silent = { silent = true }

-- Change netrw default mappings
vim.api.nvim_create_autocmd("filetype", {
    pattern = "netrw",
    callback = function()
        vim.keymap.set("n", "l", "<CR>", { remap = true, buffer = true })
        vim.keymap.set("n", "h", "-<esc>", { remap = true, buffer = true })
    end,
})

-- vim.keymap.set("n", "-", ":NvimTreeToggle<CR>")
vim.keymap.set("n", "-", ":Explore<CR>")

-- Reload vim config
vim.keymap.set("n", "<Leader><CR>", ":source %<CR>")

-- yank to system clipboard
vim.keymap.set("n", "<leader>y", '"+y')
vim.keymap.set("v", "<leader>y", '"+y')
vim.keymap.set("n", "<leader>Y", '"+Y')

-- Don't yank with x and d
vim.keymap.set("n", "x", '"_x')
vim.keymap.set("n", "<leader>d", '"_d')
vim.keymap.set("v", "<leader>d", '"_d')
-- Also during paste, delete to another reg
vim.keymap.set("x", "P", '"_dP')

-- Increment/decrement
-- vim.keymap.set("n", "+", "<C-a>")
-- vim.keymap.set("n", "_", "<C-x>")

-- Select all
vim.keymap.set("n", "<C-a>", "gg<S-v>G")
-- Move a selected line of text using ALT+[jk]
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv")
-- vim.keymap.set("n", "<A-j>", ":m '>+1<CR>gv=gv mz:m+<cr>`z")
--

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "Q", "<nop>")

-- New tab
vim.keymap.set("n", "te", ":tabedit<CR>", silent)

-- Split window
vim.keymap.set("n", "ss", ":split<CR><C-w>w", silent)
vim.keymap.set("n", "sv", ":vsplit<CR><C-w>w", silent)

-- Move window
vim.keymap.set("n", "<Space>j", "<C-w>w")
vim.keymap.set("n", "sh", "<C-w>h")
vim.keymap.set("n", "sk", "<C-w>k")
vim.keymap.set("n", "sj", "<C-w>j")
vim.keymap.set("n", "sl", "<C-w>l")

-- Resize window
vim.keymap.set("n", "<C-w><left>", "<C-w><")
vim.keymap.set("n", "<C-w><right>", "<C-w>>")
vim.keymap.set("n", "<C-w><up>", "<C-w>+")
vim.keymap.set("n", "<C-w><down>", "<C-w>-")
vim.keymap.set("n", "<leader>=", "<C-w>=")
vim.keymap.set("n", "<leader>m", ":MaximizerToggle<CR>", silent)
vim.keymap.set("v", "<leader>m", ":MaximizerToggle<CR>gv", silent)
vim.keymap.set("i", "<F3>", "<C-o>:MaximizerToggle<CR>", silent)

-- tmux-sessionizer
vim.keymap.set("n", "<C-f>", ":silent !tmux neww ~/code/dotfiles/zsh/.config/zsh/tmux-sessionizer.sh<CR>", silent)

-- undotree
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

-- move between qf list
vim.keymap.set("n", "<leader>c", "<cmd>cclose<CR>")
vim.keymap.set("n", "<leader>n", "<cmd>cnext<CR>")
vim.keymap.set("n", "<leader>p", "<cmd>cprev<CR>")

-- console with more details
vim.keymap.set("n", "<leader>lg", "<cmd>lua require('zippy').insert_print()<CR>")

-- formatting
vim.keymap.set("n", "<leader>vf", vim.lsp.buf.format)

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
vim.keymap.set("n", "zR", require("ufo").openAllFolds)
vim.keymap.set("n", "zM", require("ufo").closeAllFolds)

-- git
vim.keymap.set("n", "<leader>r", vim.cmd.Git)
