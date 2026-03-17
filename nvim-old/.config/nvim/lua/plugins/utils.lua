return {
  {
    "windwp/nvim-ts-autotag",
    opts = {},
    config = function()
      require('nvim-ts-autotag').setup()
    end
  },
  { "szw/vim-maximizer" },
  { "mong8se/actually.nvim" },
  { "nvim-tree/nvim-web-devicons" },
  { "RRethy/vim-illuminate" },
  { "jwalton512/vim-blade" },
  { "nvim-telescope/telescope-ui-select.nvim" },
  { "PatschD/zippy.nvim" },
  {
    "numToStr/Comment.nvim",
    opts = {
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
    },
    lazy = false,
  },
  {
    "kylechui/nvim-surround",
    version = "*",
    config = function()
      require("nvim-surround").setup({})
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
  },
  {
    "j-hui/fidget.nvim",
    opts = {},
  },
}
