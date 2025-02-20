return {
    {
        -- Highlight, edit, and navigate code
        "nvim-treesitter/nvim-treesitter",
        dependencies = {
            "vrischmann/tree-sitter-templ",
        },
        build = ":TSUpdate",
    },
}
