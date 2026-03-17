-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- View a color column at 80 characters
vim.opt.colorcolumn = "80"
vim.g.lazyvim_php_lsp = "intelephense"


if vim.g.neovide then
    vim.o.guifont = "JetBrainsMono Nerd Font:h10"
    vim.g.neovide_padding_top = 0
    vim.g.neovide_padding_bottom = 0
    vim.g.neovide_padding_right = 0
    vim.g.neovide_padding_left = 0
    -- vim.g.neovide_floating_blur_amount_x = 2.0
    -- vim.g.neovide_floating_blur_amount_y = 2.0
    -- vim.g.neovide_transparency = 0.9
    if vim.fn.argc() == 0 then
      vim.cmd("cd C:/Users/shiya/dev")
    end
end

