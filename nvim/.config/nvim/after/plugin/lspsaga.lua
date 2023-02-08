local status, saga = pcall(require, "lspsaga")
if not status then
    return
end

saga.setup({
    server_filetype_map = {
        typescript = "typescript",
    },
    lightbulb = {
        enable = false,
        enable_in_insert = false,
    },
    symbol_in_winbar = {
        folder_level = 1,
        color_mode = false,
    },
})
