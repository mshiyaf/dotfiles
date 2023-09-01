return {
    {
        "windwp/nvim-autopairs",
        "windwp/nvim-ts-autotag",
        "folke/zen-mode.nvim",
        "szw/vim-maximizer",
        "mong8se/actually.nvim",
        "nvim-tree/nvim-web-devicons",
        "lukas-reineke/indent-blankline.nvim",
        "RRethy/vim-illuminate",
        "jwalton512/vim-blade",
        "nvim-telescope/telescope-ui-select.nvim",
        "JoosepAlviste/nvim-ts-context-commentstring",
        "PatschD/zippy.nvim",
        config = function()
            local autopairs = require("nvim-autopairs")

            autopairs.setup({
                disable_filetype = { "TelescopePrompt", "vim" },
            })

            require("Comment").setup({
                pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
            })
            local zenMode = require("zen-mode")
            zenMode.setup({})
            local autotag = require("nvim-ts-autotag")
            autotag.setup({})
            vim.keymap.set("n", "<C-w>o", "<cmd>ZenMode<cr>", { silent = true })
        end,
    },

    {
        "kylechui/nvim-surround",
        version = "*",
        config = function()
            require("nvim-surround").setup({})
        end,
    },
}
