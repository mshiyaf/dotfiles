return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>vf",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" },
      javascript = { { "prettierd", "prettier" } },
      javascriptreact = { { "prettierd", "prettier" } },
      typescript = { { "prettierd", "prettier" } },
      typescriptreact = { { "prettierd", "prettier" } },
      markdown = { { "prettierd", "prettier" } },
      json = { { "prettierd", "prettier" } },
      css = { { "prettierd", "prettier" } },
      html = { { "prettierd", "prettier" } },
      go = { "goimports", "gofmt" },
      sql = { "sql_formatter" },
      ["_"] = { "trim_whitespace" },
    },
    formatters = {
      sql_formatter = {
        exe = "sql-formatter",
        args = { "--language", "postgresql", "--config", '{"keywordCase": "upper"}' },
      },

    },
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
  },
}
