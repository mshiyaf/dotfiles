return {
    {
        "folke/tokyonight.nvim",
        lazy = true,
        opts = {
            style = "night",
            transparent = "true",
            styles = {
                -- Style to be applied to different syntax groups
                -- Value is any valid attr-list value for `:help nvim_set_hl`
                comments = { italic = true },
                keywords = { italic = true },
                functions = {},
                variables = {},
                -- Background styles. Can be "dark", "transparent" or "normal"
                sidebars = "transparent", -- style for sidebars, see below
                floats = "transparent", -- style for floating windows
            },
        },
    },
    -- catppuccin
    {
        "catppuccin/nvim",
        opts = {
            -- flavour = "frappe",
            transparent_background = true,
            styles = {
                sidebars = "transparent",
                floats = "transparent",
            },
        },
    },
    -- Configure LazyVim to load the colorscheme
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "catppuccin",
        },
    },
}
