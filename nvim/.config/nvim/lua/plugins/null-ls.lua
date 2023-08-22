return {
    "jose-elias-alvarez/null-ls.nvim",
    "jay-babu/mason-null-ls.nvim",
    config = function()
        require("mason-null-ls").setup({
            ensure_installed = {
                "prettierd",
                "stylua",
                "blade-formatter",
                "phpcsfixer",
                "fixjson",
                "gofmt",
                "sqlfluff",
            },
            automatic_installation = false,
            automatic_setup = false,
        })
        local null_ls = require("null-ls")

        null_ls.setup {
            sources = {
                null_ls.builtins.formatting.prettierd,
                null_ls.builtins.formatting.stylua,
                null_ls.builtins.formatting.blade_formatter,
                null_ls.builtins.formatting.phpcsfixer,
                null_ls.builtins.formatting.fixjson,
                null_ls.builtins.formatting.gofmt,
                null_ls.builtins.formatting.sqlfluff,
            },
        }
    end,
}
