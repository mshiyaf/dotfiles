return {
    {
        "folke/tokyonight.nvim",
        lazy = true,
        opts = { style = "night" },
    },
    -- Configure LazyVim to load the colorscheme
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "tokyonight",
        },
    },
}
