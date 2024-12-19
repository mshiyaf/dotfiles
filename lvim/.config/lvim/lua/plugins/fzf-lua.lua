return {
    -- change fzf-lua config
    {
        "ibhagwan/fzf-lua",
        opts = function(_, _)
            local actions = require("fzf-lua.actions")
            return {
                files = {
                    cwd_prompt = false,
                    actions = {
                        ["ctrl-h"] = { actions.toggle_hidden },
                    },
                },
                grep = {
                    actions = {
                        ["ctrl-h"] = { actions.toggle_hidden },
                    },
                },
            }
        end,
    },
}
