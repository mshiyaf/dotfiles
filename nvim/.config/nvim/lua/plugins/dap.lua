return {
  {
    "mfussenegger/nvim-dap",
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      require("dapui").setup()
    end,
  },
  -- {
  --   "leoluz/nvim-dap-go",
  --   requires = { "mfussenegger/nvim-dap" },
  --   config = function()
  --     require("dap-go").setup()
  --   end,
  -- },
  { "nvim-telescope/telescope-dap.nvim" },
  { "theHamsta/nvim-dap-virtual-text" },
}
