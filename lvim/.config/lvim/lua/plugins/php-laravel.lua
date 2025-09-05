return {
    {
        -- Set Laravel Pint as the default PHP formatter with PHP CS Fixer as a fall back.
        "stevearc/conform.nvim",
        optional = true,
        opts = {
            formatters_by_ft = {
                php = { "pint" },
                blade = { "blade-formatter" },
            },
        },
    },
    {
        -- Add the blade-nav.nvim plugin which provides Goto File capabilities
        -- for Blade files.
        "ricardoramirezr/blade-nav.nvim",
        ft = { "blade", "php" },
    },
    {
        -- Remove phpcs linter.
        "mfussenegger/nvim-lint",
        optional = true,
        opts = {
            linters_by_ft = {
                php = {},
            },
        },
    },
    {
        "adalessa/laravel.nvim",
        dependencies = {
            "tpope/vim-dotenv",
            "nvim-telescope/telescope.nvim",
            "MunifTanjim/nui.nvim",
            "kevinhwang91/promise-async",
        },
        cmd = { "Laravel" },
        -- keys = {
        --     { "<leader>la", ":Laravel artisan<cr>" },
        --     { "<leader>lr", ":Laravel routes<cr>" },
        --     { "<leader>lm", ":Laravel related<cr>" },
        -- },
        event = { "VeryLazy" },
        opts = {
            pickers = {
                enable = true,
                provider = "fzf-lua",
            },
        },
        config = true,
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                intelephense = {
                    settings = {
                        intelephense = {
                            files = {
                                maxSize = 1000000,
                                associations = { "*.php", "*.phtml" },
                                exclude = {
                                    "**/node_modules/**",
                                    "**/vendor/**/Tests/**",
                                    "**/vendor/**/tests/**",
                                },
                            },
                            environment = {
                                includePaths = {
                                    "./vendor/", -- Make sure vendor is included
                                },
                            },
                        },
                    },
                },
            },
        },
    },
}
