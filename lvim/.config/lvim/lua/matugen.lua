local M = {}

function M.setup()
    require("base16-colorscheme").setup({
        -- Background tones
        base00 = "#0b0e14", -- Default Background
        base01 = "#1e222a", -- Lighter Background (status bars)
        base02 = "#262c36", -- Selection Background
        base03 = "#595f6a", -- Comments, Invisibles
        -- Foreground tones
        base04 = "#636a72", -- Dark Foreground (status bars)
        base05 = "#bfbdb6", -- Default Foreground
        base06 = "#bfbdb6", -- Light Foreground
        base07 = "#bfbdb6", -- Lightest Foreground
        -- Accent colors
        base08 = "#d95757", -- Variables, XML Tags, Errors
        base09 = "#39bae6", -- Integers, Constants
        base0A = "#aad94c", -- Classes, Search Background
        base0B = "#e6b450", -- Strings, Diff Inserted
        base0C = "#8ed8f1", -- Regex, Escape Chars
        base0D = "#efcf8f", -- Functions, Methods
        base0E = "#cde996", -- Keywords, Storage
        base0F = "#700e0e", -- Deprecated, Embedded Tags
    })
end

-- Register a signal handler for SIGUSR1 (matugen updates)
local signal = vim.uv.new_signal()
signal:start(
    "sigusr1",
    vim.schedule_wrap(function()
        package.loaded["matugen"] = nil
        require("matugen").setup()
    end)
)

return M
