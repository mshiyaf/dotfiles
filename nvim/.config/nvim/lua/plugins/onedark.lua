return {
    "navarasu/onedark.nvim",
    config = function()
        require("onedark").setup({
            style = 'darker',
            transparent = true,
        })
        vim.cmd([[colorscheme onedark]])
    end
}
