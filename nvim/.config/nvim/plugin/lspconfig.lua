--vim.lsp.set_log_level("debug")
local Remap = require("keymap")
local nnoremap = Remap.nnoremap
local inoremap = Remap.inoremap

local status, nvim_lsp = pcall(require, "lspconfig")
if not status then
	return
end

local protocol = require("vim.lsp.protocol")

local function config(_config)
	return vim.tbl_deep_extend("force", {
		capabilities = require("cmp_nvim_lsp").update_capabilities(vim.lsp.protocol.make_client_capabilities()),
		on_attach = function(client)
			if client.name == "tsserver" then
				client.resolved_capabilities.document_formatting = false
			end
			if client.name == "sumneko_lua" then
				client.resolved_capabilities.document_formatting = false
			end
			nnoremap("gi", function()
				vim.lsp.buf.implementation()
			end)
			nnoremap("gD", function()
				vim.lsp.buf.declaration()
			end)
			nnoremap("<leader>vws", function()
				vim.lsp.buf.workspace_symbol()
			end)
			nnoremap("<leader>vd", function()
				vim.diagnostic.open_float()
			end)
			nnoremap("[d", function()
				vim.diagnostic.goto_next()
			end)
			nnoremap("]d", function()
				vim.diagnostic.goto_prev()
			end)
			nnoremap("<leader>vca", function()
				vim.lsp.buf.code_action()
			end)
			nnoremap("<leader>vrr", function()
				vim.lsp.buf.references()
			end)
			nnoremap("<leader>vrn", function()
				vim.lsp.buf.rename()
			end)
			inoremap("<C-h>", function()
				vim.lsp.buf.signature_help()
			end)
			vim.cmd([[ command! Format execute 'lua vim.lsp.buf.formatting()' ]])
		end,
	}, _config or {})
end

protocol.CompletionItemKind = {
	"", -- Text
	"", -- Method
	"", -- Function
	"", -- Constructor
	"", -- Field
	"", -- Variable
	"", -- Class
	"ﰮ", -- Interface
	"", -- Module
	"", -- Property
	"", -- Unit
	"", -- Value
	"", -- Enum
	"", -- Keyword
	"﬌", -- Snippet
	"", -- Color
	"", -- File
	"", -- Reference
	"", -- Folder
	"", -- EnumMember
	"", -- Constant
	"", -- Struct
	"", -- Event
	"ﬦ", -- Operator
	"", -- TypeParameter
}

nvim_lsp.eslint.setup(config())

nvim_lsp.flow.setup(config())

nvim_lsp.tsserver.setup(config())

nvim_lsp.sourcekit.setup(config())

nvim_lsp.sumneko_lua.setup(config({
	settings = {
		Lua = {
			runtime = {
				-- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
				version = "LuaJIT",
				-- Setup your lua path
				path = vim.split(package.path, ";"),
			},
			diagnostics = {
				-- Get the language server to recognize the `vim` global
				globals = { "vim" },
			},
			workspace = {
				-- Make the server aware of Neovim runtime files
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
		},
	},
}))

nvim_lsp.tailwindcss.setup(config())

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
	underline = true,
	update_in_insert = false,
	virtual_text = { spacing = 4, prefix = "●" },
	severity_sort = true,
})

-- Diagnostic symbols in the sign column (gutter)
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

vim.diagnostic.config({
	virtual_text = {
		prefix = "●",
	},
	update_in_insert = true,
	float = {
		source = "always", -- Or "if_many"
	},
})
