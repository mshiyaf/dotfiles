return {
    "navarasu/onedark.nvim",
    config = function()
        if vim.g.neovide then
            require("onedark").setup({
                style = 'darker',
                transparent = false,
            })
        else
            require("onedark").setup({
                style = 'darker',
                transparent = true,
            })
        end
        vim.cmd([[colorscheme onedark]])
    end
}
