-- add 2 commands:
--    CodeCompanionSave [space delimited args]
--    CodeCompanionLoad
-- Save will save current chat in a md file named 'space-delimited-args.md'
-- Load will use a telescope filepicker to open a previously saved chat

-- create a folder to store our chats
local Path = require("plenary.path")
local data_path = vim.fn.stdpath("data") -- ~/.local/share/<NVIM_APPNAME>
local save_folder = Path:new(data_path, "codecompanion_chats")
if not save_folder:exists() then
    save_folder:mkdir({ parents = true })
end

-- snacks picker for our saved chats
vim.api.nvim_create_user_command("CodeCompanionLoad", function()
    local Snacks = require("snacks")
    local files = vim.fn.glob(save_folder:absolute() .. "/*.md", false, true)
    local items = {}

    for i, file in ipairs(files) do
        local filename = vim.fn.fnamemodify(file, ":t")
        table.insert(items, {
            id = i,
            value = file,
            display = filename,
            file = file,
            text = filename,
        })
    end

    return Snacks.picker({
        name = "saved_codecompanion_chats",
        title = "Saved CodeCompanion Chats",
        items = items,
        format = function(item)
            local ret = {}
            ret[#ret + 1] = { item.display, "SnacksPickerLabel" }
            ret[#ret + 1] = {
                " (" .. vim.fn.fnamemodify(item.value, ":h:t") .. ")",
                "SnacksPickerComment",
            }
            return ret
        end,
        confirm = function(picker, item)
            picker:close()
            vim.cmd("edit " .. item.value)
        end,
        preview = "file",
        matcher = {
            fields = { "text" },
        },
        actions = {
            delete_chat = function(picker, item)
                if not item then
                    return
                end
                local ok, choice = pcall(
                    vim.fn.confirm,
                    ("Delete chat %q?"):format(item.display),
                    "&Yes\n&No\n&Cancel"
                )
                if not ok or choice == 0 or choice == 3 then -- 0 for <Esc>/<C-c> and 3 for Cancel
                    return
                end
                if choice == 1 then -- Yes
                    os.remove(item.value)

                    -- Refresh the items list with updated files
                    local files = vim.fn.glob(save_folder:absolute() .. "/*.md", false, true)
                    local new_items = {}

                    for i, file in ipairs(files) do
                        local filename = vim.fn.fnamemodify(file, ":t")
                        table.insert(new_items, {
                            id = i,
                            value = file,
                            display = filename,
                            file = file,
                            text = filename,
                        })
                    end

                    -- Update the picker with new items
                    picker.opts.items = new_items
                    picker:find({ refresh = true })
                end
            end,
        },
        win = {
            input = {
                keys = {
                    ["<c-d>"] = { "delete_chat", mode = { "n", "i" } },
                },
            },
            list = {
                keys = {
                    ["<c-d>"] = { "delete_chat", mode = { "n" } },
                },
            },
        },
    })
end, {})

-- save current chat, `CodeCompanionSave foo bar baz` will save as 'foo-bar-baz.md'
vim.api.nvim_create_user_command("CodeCompanionSave", function(opts)
    local codecompanion = require("codecompanion")
    local success, chat = pcall(function()
        return codecompanion.buf_get_chat(0)
    end)
    if not success or chat == nil then
        vim.notify(
            "CodeCompanionSave should only be called from CodeCompanion chat buffers",
            vim.log.levels.ERROR
        )
        return
    end
    if #opts.fargs == 0 then
        vim.notify(
            "CodeCompanionSave requires at least 1 arg to make a file name",
            vim.log.levels.ERROR
        )
        return
    end
    local save_name = table.concat(opts.fargs, "-") .. ".md"
    local save_path = Path:new(save_folder, save_name)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    save_path:write(table.concat(lines, "\n"), "w")
end, { nargs = "*" })

--- Anthropic config for CodeCompanion.
local anthropic_fn = function()
    local anthropic_config = {
        env = {
            api_key = "cmd:gpg --pinentry-mode loopback --decrypt ~/anthropic_api_key.txt.asc",
        },
    }
    return require("codecompanion.adapters").extend(
        "anthropic",
        anthropic_config
    )
end

--- --- OpenAI config for CodeCompanion.
--- local openai_fn = function()
---     local openai_config = {
---         env = {
---             api_key = "cmd:gpg --pinentry-mode loopback --decrypt anthropic_api_key.txt.asc",
---         },
---     }
---     return require("codecompanion.adapters").extend("openai", openai_config)
--- end

return {
    {
        "olimorris/codecompanion.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "nvim-telescope/telescope.nvim",
            {
                "stevearc/dressing.nvim",
                opts = {},
            },
            {
                "saghen/blink.cmp",
                ---@module 'blink.cmp'
                ---@type blink.cmp.Config
                opts = {
                    sources = {
                        default = { "codecompanion" },
                        providers = {
                            codecompanion = {
                                name = "CodeCompanion",
                                module = "codecompanion.providers.completion.blink",
                                enabled = true,
                            },
                        },
                    },
                },
            },
            {
                "nvim-lualine/lualine.nvim",
                opts = {
                    options = {
                        disabled_filetypes = { "codecompanion" },
                    },
                },
            },
        },
        keys = function()
            -- Import keymaps from config/keymaps.lua
            local keymaps_module = require("config.keymaps")
            return keymaps_module.setup_codecompanion_keymaps()
        end,
        opts = function(_, opts)
            local custom_opts = {
                adapters = {
                    anthropic = anthropic_fn,
                    -- openai = openai_fn,
                },
            }

            return vim.tbl_deep_extend("force", opts, custom_opts)
        end,

        config = function(_, opts)
            require("codecompanion").setup(opts)
        end,
    },
}
