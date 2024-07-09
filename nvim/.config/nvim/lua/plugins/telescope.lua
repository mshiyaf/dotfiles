return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local actions = require("telescope.actions")
    require("telescope").setup({
      defaults = {
        mappings = {
          n = {
            ["q"] = actions.close,
            ["<C-e>"] = actions.select_tab,
            ["l"] = actions.select_default,
            ["<C-s>"] = actions.select_vertical,
          },
          i = {
            ["<C-e>"] = actions.select_tab,
            ["<C-s>"] = actions.select_vertical,
          },
        },
        prompt_prefix = "   ",
        -- selection_caret = "  ",
        file_sorter = require("telescope.sorters").get_fuzzy_file,
        file_ignore_patterns = { "node_modules", "vendor", ".git", ".cache" },
        generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
        path_display = { "truncate" },
        winblend = 0
      },
    })

    local builtin = require("telescope.builtin")

    vim.keymap.set("n", "<leader>f", function()
      builtin.git_files({
        hidden = true,
      })
    end)
    -- vim.keymap.set("n", "<leader>f", function()
    -- 	builtin.find_files({
    -- 		show_untracked = true,
    -- 	})
    -- end)
    vim.keymap.set("n", "<leader>g", function()
      builtin.live_grep({
        -- additional_args = function()
        --     return { "--hidden" }
        -- end,
      })
    end)
    vim.keymap.set("n", "<leader>b", function()
      builtin.buffers()
    end)
    vim.keymap.set("n", "<leader>r", function()
      builtin.resume()
    end)
    vim.keymap.set("n", "<leader>t", function()
      builtin.commands()
    end)

    require("telescope").load_extension("git_worktree")
    require("telescope").load_extension("dap")

    vim.keymap.set("n", "<leader>;", "<cmd>lua require('telescope').extensions.git_worktree.git_worktrees()<cr>")
    vim.keymap.set(
      "n",
      "<leader>cw",
      "<cmd>lua require('telescope').extensions.git_worktree.create_git_worktree()<cr>"
    )

    require("telescope").load_extension("git_worktree")

    local Worktree = require("git-worktree")
    Worktree.on_tree_change(function(op, metadata)
      if op == Worktree.Operations.Switch then
        print("Switched from " .. metadata.prev_path .. " to " .. metadata.path)
      end
    end)


    local harpoon = require('harpoon')
    harpoon:setup({})

    -- basic telescope configuration
    local conf = require("telescope.config").values
    local function toggle_telescope(harpoon_files)
      local file_paths = {}
      for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
      end

      require("telescope.pickers").new({}, {
        prompt_title = "Harpoon",
        finder = require("telescope.finders").new_table({
          results = file_paths,
        }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
      }):find()
    end

    vim.keymap.set("n", "<C-e>", function() toggle_telescope(harpoon:list()) end,
      { desc = "Open harpoon window" })
  end,
}
