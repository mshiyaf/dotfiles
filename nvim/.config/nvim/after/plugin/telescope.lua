local status, telescope = pcall(require, "telescope")
if not status then
    return
end
local actions = require("telescope.actions")
local builtin = require("telescope.builtin")

telescope.setup({
    defaults = {
        prompt_prefix = " ",
        selection_caret = "  ",
        entry_prefix = "  ",
        mappings = {
            n = {
                ["q"] = actions.close,
                ["<C-e>"] = actions.select_tab,
                ["l"] = actions.select_default,
                ["<C-s>"] = actions.select_vertical,
            },
            i = {
                ["<C-e>"] = actions.select_tab,
                ["<C-s>"] = actions.select_vertical,
            },
        },
    },
})

vim.keymap.set("n", "<leader>f", function()
    builtin.find_files({
        hidden = true,
    })
end)
vim.keymap.set("n", "<leader>g", function()
    builtin.live_grep({
        additional_args = function()
            return { "--hidden" }
        end,
    })
end)
vim.keymap.set("n", "<leader>b", function()
    builtin.buffers()
end)
vim.keymap.set("n", "<leader>t", function()
    builtin.resume()
end)

require("telescope").load_extension("git_worktree")
require('telescope').load_extension('dap')

vim.keymap.set("n", "<leader>;", ":lua require('telescope').extensions.git_worktree.git_worktrees()<cr>")
vim.keymap.set("n", "<leader>cw", ":lua require('telescope').extensions.git_worktree.create_git_worktree()<cr>")
