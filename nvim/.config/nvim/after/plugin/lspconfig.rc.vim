lua << EOF
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

require'lspconfig'.clangd.setup {
    on_attach = on_attach,
    root_dir = function() return vim.loop.cwd() end,
    capabilities = capabilities
}

require'lspconfig'.gopls.setup{
    on_attach=on_attach,
    cmd = {"gopls", "serve"},
    settings = {
        gopls = {
            analyses = {
                unusedparams = true,
            },
            staticcheck = true,
        },
    },
    capabilities = capabilities
}

require'lspconfig'.svelte.setup{}

require'lspconfig'.yamlls.setup{}

require'lspconfig'.tailwindcss.setup{}

require'lspconfig'.pylsp.setup{}

require'lspconfig'.tsserver.setup {
  on_attach = on_attach,
  capabilities = capabilities
}


-- icon
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = true,
    -- This sets the spacing and the prefix, obviously.
    virtual_text = {
      spacing = 4,
      prefix = ''
    }
  }
)

local snippets_paths = function()
    local plugins = { "friendly-snippets" }
    local paths = {}
    local path
    local root_path = vim.env.HOME .. '/.vim/plugged/'
    for _, plug in ipairs(plugins) do
        path = root_path .. plug
        if vim.fn.isdirectory(path) ~= 0 then
            table.insert(paths, path)
        end
    end
    return paths
end

require("luasnip.loaders.from_vscode").lazy_load({
    paths = snippets_paths(),
    include = nil,  -- Load all languages
    exclude = {}
})


EOF

nnoremap <leader>d :lua vim.lsp.buf.definition()<CR>
nnoremap <leader>i :lua vim.lsp.buf.implementation()<CR>
nnoremap <leader>vsh :lua vim.lsp.buf.signature_help()<CR>
" nnoremap <leader>rr :lua vim.lsp.buf.references()<CR>
" nnoremap <leader>rn :lua vim.lsp.buf.rename()<CR>
" nnoremap <leader>vh :lua vim.lsp.buf.hover()<CR>
" nnoremap <leader>ca :lua vim.lsp.buf.code_action()<CR>
" nnoremap <leader>ld :lua vim.lsp.diagnostic.show_line_diagnostics(); vim.lsp.util.show_line_diagnostics()<CR>
nnoremap <leader>ll :call LspLocationList()<CR>
nnoremap <leader>c :cclose<CR>
nnoremap <leader>n :cnext<CR>
nnoremap <leader>p :cprev<CR>
