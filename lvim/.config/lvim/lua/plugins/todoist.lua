return {
    "mshiyaf/todoist.nvim",
    -- dir = "/home/mshiyaf/dev/personal/todoist.nvim",
    dependencies = { "ibhagwan/fzf-lua" },
    config = function()
        require("todoist").setup({
            -- optional overrides
            default_project = nil, -- default project id
            default_priority = nil, -- 1-4 per Todoist docs
        })
    end,
}
