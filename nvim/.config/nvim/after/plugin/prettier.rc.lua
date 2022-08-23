local status, prettier = pcall(require, "prettier")
if not status then
	return
end

prettier.setup({
	bin = "prettier",
	filetypes = {
		"css",
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"json",
		"scss",
		"less",
	},
	cli_options = {
		semi = true,
		single_quote = true,
		tab_width = 2,
		print_width = 80,
		arrow_parens = "avoid",
		bracket_spacing = false,
		bracket_same_line = false,
		embedded_language_formatting = "auto",
		end_of_line = "lf",
		html_whitespace_sensitivity = "css",
		jsx_single_quote = true,
		single_attribute_per_line = false,
		trailing_comma = "es5",
		use_tabs = false,
	},
	["null-ls"] = {
		runtime_condition = function(params)
			-- return false to skip running prettier
			return true
		end,
		timeout = 5000,
	},
})
