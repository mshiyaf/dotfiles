-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- local M = {}

-- silent
local silent = { silent = true }

--  Replace the default <C-f> mapping with a custom mapping
vim.keymap.del("n", "<C-f>")
-- vim.keymap.del("s", "<C-f>")

-- Set your custom mapping
vim.keymap.set(
    "n",
    "<C-f>",
    "<cmd>silent !tmux neww ~/code/dotfiles/zsh/.config/zsh/tmux-sessionizer.sh<CR>",
    silent
)

-- function M.setup_codecompanion_keymaps()
--     return {
--         {
--             "<leader>ac",
--             ":CodeCompanionChat anthropic<CR>",
--             desc = "Codecompanion: Claude",
--         },
--         {
--             "<leader>ao",
--             ":CodeCompanionChat deepinfra<CR>",
--             desc = "Codecompanion: DeepInfra",
--         },
--         {
--             "<leader>ag",
--             ":CodeCompanionChat gemini<CR>",
--             desc = "Codecompanion: Gemini",
--         },
--         {
--             "<leader>ad",
--             ":CodeCompanionChat deepseek<CR>",
--             desc = "Codecompanion: DeepSeek",
--         },
--         {
--             "<leader>al",
--             ":CodeCompanionChat ollama<CR>",
--             desc = "Codecompanion: Ollama",
--         },
--
--         {
--             "<leader>at",
--             ":CodeCompanionChat Toggle<CR>",
--             desc = "Codecompanion toggle",
--         },
--         {
--             "<leader>aS",
--             function()
--                 local name = vim.fn.input("Save as: ")
--                 if name and name ~= "" then
--                     vim.cmd("CodeCompanionSave " .. name)
--                 end
--             end,
--             desc = "Codecompanion Save chat",
--         },
--         {
--             "<leader>aL",
--             ":CodeCompanionLoad<CR>",
--             desc = "Codecompanion Load chat",
--         },
--         {
--             "<leader>aP",
--             ":CodeCompanionActions<CR>",
--             desc = "Codecompanion Prompts",
--         },
--     }
-- end
--
-- return M
