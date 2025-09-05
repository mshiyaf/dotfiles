return {
    {
        -- Highlight, edit, and navigate code
        "nvim-treesitter/nvim-treesitter",
        dependencies = {
            "vrischmann/tree-sitter-templ",
        },
        build = ":TSUpdate",
    },
    {
        -- Add ensure installed for mason
        "mason-org/mason.nvim",
        opts = {
            ensure_installed = {
                "blade-formatter",
                "intelephense",
            },
        },
    },
}
