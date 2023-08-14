local run_formatter = function(text)
	local split = vim.split(text, "\n")
	local result = table.concat(vim.list_slice(split, 2, #split - 1), "\n")

	-- Finds sql-format-via-python somewhere in your nvim config path
	local bin = vim.api.nvim_get_runtime_file("bin/sql_js_format.py", false)[1]

	local j = require("plenary.job"):new({
		command = "python3",
		args = { bin },
		writer = { result },
	})
	return j:sync()
end

local embedded_sql = vim.treesitter.query.parse(
	"javascript",
	[[
(call_expression
function: (identifier) @_name
(#eq? @_name "sql")
arguments: (template_string) @sql
)
    ]]
)

local get_root = function(bufnr)
	local parser = vim.treesitter.get_parser(bufnr, "javascript", {})
	local tree = parser:parse()[1]
	return tree:root()
end

local format_dat_sql = function(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	if vim.bo[bufnr].filetype ~= "javascript" then
		vim.notify("can onlly be user in js file")
		return
	end
	local root = get_root(bufnr)
	local changes = {}
	for id, node in embedded_sql:iter_captures(root, bufnr, 0, -1) do
		local name = embedded_sql.captures[id]
		if name == "sql" then
			local range = { node:range() }
			local indentation = string.rep(" ", range[4])
			-- Run the formatter, based on the node text

			local formatted = run_formatter(vim.treesitter.get_node_text(node, bufnr))
			-- Add some indentation (can be anything you like!)
			for idx, line in ipairs(formatted) do
				formatted[idx] = indentation .. line
			end

			-- Keep track of changes
			--    But insert them in reverse order of the file,
			--    so that when we make modifications, we don't have
			--    any out of date line numbers
			table.insert(changes, 1, {
				start = range[1] + 1,
				final = range[3],
				formatted = formatted,
			})
		end
	end
	for _, change in ipairs(changes) do
		vim.api.nvim_buf_set_lines(bufnr, change.start, change.final, false, change.formatted)
	end
end

vim.api.nvim_create_user_command("SqlMagic", function()
	format_dat_sql()
end, {})
