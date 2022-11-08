--vim.lsp.set_log_level("debug")
local Remap = require("keymap")
local breadcrumbs = require("breadcrumbs")
local nnoremap = Remap.nnoremap
local inoremap = Remap.inoremap

-- require("inlay-hints").setup()

local status_navic, navic = pcall(require, "nvim-navic")
if not status_navic then
	return
end

local status, nvim_lsp = pcall(require, "lspconfig")
if not status then
	return
end

local protocol = require("vim.lsp.protocol")

local function config(_config)
	return vim.tbl_deep_extend("force", {
		capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities()),
		on_attach = function(client, bufnr)
			if client.name == "tsserver" then
				-- require("inlay-hints").on_attach(client, bufnr)
				client.server_capabilities.document_formatting = false
			end
			if client.name == "sumneko_lua" then
				client.server_capabilities.document_formatting = false
			end
			if client.name == "intelephense" then
				client.server_capabilities.document_formatting = false
			end
			if client.server_capabilities.documentSymbolProvider then
				navic.attach(client, bufnr)
			end
			nnoremap("gi", function()
				vim.lsp.buf.implementation()
			end)
			nnoremap("gd", function()
				vim.lsp.buf.definition()
			end)
			nnoremap("gD", function()
				vim.lsp.buf.declaration()
			end)
			inoremap("<C-h>", function()
				vim.lsp.buf.signature_help()
			end)
			nnoremap("<leader>vws", function()
				vim.lsp.buf.workspace_symbol()
			end)
			vim.cmd([[ command! Format execute 'lua vim.lsp.buf.format({async = true})' ]])
		end,
	}, _config or {})
end

protocol.CompletionItemKind = {
	"", -- Text
	"", -- Method
	"", -- Function
	"", -- Constructor
	"", -- Field
	"", -- Variable
	"", -- Class
	"", -- Interface
	"", -- Module
	"", -- Property
	"", -- Unit
	"", -- Value
	"", -- Enum
	"", -- Keyword
	"", -- Snippet
	"", -- Color
	"", -- File
	"", -- Reference
	"", -- Folder
	"", -- EnumMember
	"", -- Constant
	"", -- Struct
	"", -- Event
	"", -- Operator
	"", -- TypeParameter
}

nvim_lsp.clangd.setup(config())

nvim_lsp.eslint.setup(config())

nvim_lsp.tsserver.setup(config())

nvim_lsp.intelephense.setup(config())

nvim_lsp.sourcekit.setup(config())

nvim_lsp.sumneko_lua.setup(config({
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
				path = vim.split(package.path, ";"),
			},
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
		},
	},
}))

nvim_lsp.tailwindcss.setup(config())

breadcrumbs.setup()

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
