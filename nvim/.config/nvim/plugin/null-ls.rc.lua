local status, null_ls = pcall(require, "null-ls")
if not status then
	return
end

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local formatting = null_ls.builtins.formatting

null_ls.setup({
	-- on_attach = function(client, bufnr)
	-- 	if client.supports_method("textDocument/formatting") then
	-- 		vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
	-- 		vim.api.nvim_create_autocmd("BufWritePre", {
	-- 			group = augroup,
	-- 			buffer = bufnr,
	-- 			callback = function()
	-- 				vim.lsp.buf.format({ bufnr = bufnr })
	-- 			end,
	-- 		})
	-- 	end
	-- end,
	debug = false,
	sources = {
		formatting.stylua,
		formatting.blade_formatter,
		formatting.prettierd,
		formatting.phpcsfixer
	},
})
