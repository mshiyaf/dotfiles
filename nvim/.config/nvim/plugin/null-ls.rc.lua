local status, null_ls = pcall(require, "null-ls")
if not status then
	return
end

local formatting = null_ls.builtins.formatting

null_ls.setup({
	debug = false,
	sources = {
		formatting.stylua,
		formatting.blade_formatter,
		formatting.prettierd,
		formatting.phpcsfixer,
		formatting.fixjson,
	},
})
