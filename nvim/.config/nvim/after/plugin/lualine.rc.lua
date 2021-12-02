local lualine = require "lualine"

local colors = {
    bg = "#202328",
    fg = "#bbc2cf",
    yellow = "#ECBE7B",
    cyan = "#008080",
    green = "#98be65",
    orange = "#FF8800",
    violet = "#a9a1e1",
    magenta = "#c678dd",
    red = "#ec5f67"
}

local conditions = {
    buffer_not_empty = function()
        return vim.fn.empty(vim.fn.expand "%:t") ~= 1
    end,
    hide_in_width = function()
        return vim.fn.winwidth(0) > 80
    end,
    check_git_workspace = function()
        local filepath = vim.fn.expand "%:p:h"
        local gitdir = vim.fn.finddir(".git", filepath .. ";")
        return gitdir and #gitdir > 0 and #gitdir < #filepath
    end
}

-- Config
local config = {
    options = {
        -- Disable sections and component separators
        icons_enabled = true,
        component_separators = "",
        section_separators = "",
        theme = "gruvbox"
    },
    sections = {
        -- these are to remove the defaults
        lualine_a = {"mode"},
        lualine_b = {},
        lualine_y = {"progress"},
        lualine_z = {"location"},
        -- These will be filled later
        lualine_c = {},
        lualine_x = {}
    },
    inactive_sections = {
        -- these are to remove the defaults
        lualine_a = {},
        lualine_v = {},
        lualine_y = {},
        lualine_z = {},
        lualine_c = {},
        lualine_x = {}
    },
    tabline = {},
    extensions = {"fugitive"}
}

-- Inserts a component in lualine_c at left section
local function ins_left(component)
    table.insert(config.sections.lualine_c, component)
end

-- Inserts a component in lualine_x ot right section
local function ins_right(component)
    table.insert(config.sections.lualine_x, component)
end

local function ins_left_inactive(component)
    table.insert(config.inactive_sections.lualine_c, component)
end

-- Insert left section
ins_left {
    "branch",
    icon = "",
    color = {fg = colors.violet, bg = "#454545", gui = "bold"}
}

ins_left {
    "diff",
    symbols = {added = " ", modified = "柳", removed = " "},
    diff_color = {
        added = {fg = colors.green},
        modified = {fg = colors.orange},
        removed = {fg = colors.red}
    },
    cond = conditions.hide_in_width
}

-- Insert mid section.
ins_left {
    function()
        return "%="
    end
}

ins_left {
    "diagnostics",
    sources = {"nvim_lsp"},
    symbols = {error = " ", warn = " ", info = " "},
    diagnostics_color = {
        color_error = {fg = colors.red},
        color_warn = {fg = colors.yellow},
        color_info = {fg = colors.cyan}
    }
}

ins_left {
    "filename",
    cond = conditions.buffer_not_empty,
    color = {fg = colors.magenta, gui = "bold"}
}

-- Inactive mid section
ins_left_inactive {
    function()
        return "%="
    end
}

ins_left_inactive {
    "diagnostics",
    sources = {"nvim_lsp"},
    symbols = {error = " ", warn = " ", info = " "},
    diagnostics_color = {
        color_error = {fg = colors.red},
        color_warn = {fg = colors.yellow},
        color_info = {fg = colors.cyan}
    }
}

ins_left_inactive {
    "filename",
    cond = conditions.buffer_not_empty,
    color = {fg = colors.violet}
}

-- Add components to right sections

ins_right {
    "o:encoding",
    fmt = string.lower,
    cond = conditions.hide_in_width,
    color = {fg = colors.green},
    padding = {left = 0, right = 1}
}

ins_right {
    "filetype",
    icons_enabled = true,
    color = {fg = colors.green},
    padding = {left = 0, right = 1}
}

lualine.setup(config)
