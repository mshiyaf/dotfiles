local status = pcall(require, "packer")
if not status then
    print("Packer is not installed")
    return
end

vim.cmd.packadd("packer.nvim")

return require("packer").startup(function(use)
        use("wbthomason/packer.nvim")

        use({
            "nvim-telescope/telescope.nvim",
            tag = "0.1.0",
            -- or                            , branch = '0.1.x',
            requires = { { "nvim-lua/plenary.nvim" } },
        })

        use({ "catppuccin/nvim", as = "catppuccin" })

        use({
            "nvim-treesitter/nvim-treesitter",
            run = ":TSUpdate",
        })
        use("nvim-treesitter/playground")
        use("tpope/vim-vinegar")
        use("theprimeagen/harpoon")
        use("mbbill/undotree")

        use("nvim-lua/popup.nvim") -- Common utilities

        use({
            "VonHeikemen/lsp-zero.nvim",
            branch = "v1.x",
            requires = {
                -- LSP Support
                { "neovim/nvim-lspconfig" },
                { "williamboman/mason.nvim" },
                { "williamboman/mason-lspconfig.nvim" },

                -- Autocompletion
                { "hrsh7th/nvim-cmp" },
                { "hrsh7th/cmp-buffer" },
                { "hrsh7th/cmp-path" },
                { "hrsh7th/cmp-cmdline" },
                { "saadparwaiz1/cmp_luasnip" },
                { "hrsh7th/cmp-nvim-lsp" },
                { "hrsh7th/cmp-nvim-lua" },

                -- Snippets
                { "L3MON4D3/LuaSnip" },
                { "rafamadriz/friendly-snippets" },
            },
        })

        use({
            "glepnir/lspsaga.nvim",
            branch = "main",
            requires = { { "nvim-tree/nvim-web-devicons" } }
        }) -- LSP UIs

        use("nvim-lualine/lualine.nvim") -- Statusline
        use("akinsho/nvim-bufferline.lua")
        use("windwp/nvim-autopairs")
        use({ "windwp/nvim-ts-autotag", after = "nvim-treesitter" })
        use("folke/zen-mode.nvim")

        -- Git
        use("lewis6991/gitsigns.nvim")
        use("tpope/vim-fugitive")
        use("ThePrimeagen/git-worktree.nvim")
        use("sindrets/diffview.nvim")

        use("szw/vim-maximizer") -- Toggle window maximization

        use("akinsho/toggleterm.nvim")
        use("mong8se/actually.nvim")

        use("lukas-reineke/indent-blankline.nvim")

        use({
            "goolord/alpha-nvim",
            config = function()
                require("alpha").setup(require("alpha.themes.startify").config)
            end,
        })

        use("RRethy/vim-illuminate")
        use("jwalton512/vim-blade")
        use("nvim-telescope/telescope-ui-select.nvim")
        use({
            "kylechui/nvim-surround",
            tag = "*", -- Use for stability; omit to use `main` branch for the latest features
            config = function()
                require("nvim-surround").setup({
                    -- Configuration here, or leave empty to use defaults
                })
            end,
        })
        use("numToStr/Comment.nvim")
        use("JoosepAlviste/nvim-ts-context-commentstring")

        use({
            "iamcco/markdown-preview.nvim",
            run = function()
                vim.fn["mkdp#util#install"]()
            end,
        })
        use("PatschD/zippy.nvim")
        use({ "kevinhwang91/nvim-ufo", requires = "kevinhwang91/promise-async" })
    end)
