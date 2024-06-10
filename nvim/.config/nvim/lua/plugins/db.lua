return {
	{ "kristijanhusak/vim-dadbod-ui" },
	{ "kristijanhusak/vim-dadbod-completion" },
	{

		"tpope/vim-dadbod",
		opt = true,
		requires = {
			"kristijanhusak/vim-dadbod-ui",
			"kristijanhusak/vim-dadbod-completion",
		},
		config = function()
			-- autocommand for nvim-cmp completion sql, mysql, plsql, sqlite
			local db_completion = function()
				local cmp = require("cmp")
				cmp.setup.buffer({
					sources = {
						{ name = "vim-dadbod-completion" },
					},
				})
			end

			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "sql", "mysql", "pgsql", "sqlite" },
				callback = function()
					vim.schedule(db_completion)
				end,
			})
		end,
	},
}
