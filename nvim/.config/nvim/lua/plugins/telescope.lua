return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.2",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local actions = require("telescope.actions")
		require("telescope").setup({
			defaults = {
				prompt_prefix = " ",
				selection_caret = "  ",
				entry_prefix = "  ",
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
			},
		})
		local builtin = require("telescope.builtin")

		vim.keymap.set("n", "<leader>f", function()
			builtin.find_files({
				hidden = true,
			})
		end)
		-- vim.keymap.set("n", "<leader>f", function()
		-- 	builtin.git_files({
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
		vim.keymap.set("n", "<leader>t", function()
			builtin.resume()
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
		-- local Job = require('plenary.job')

		-- op = Operations.Switch, Operations.Create, Operations.Delete
		-- metadata = table of useful values (structure dependent on op)
		--      Switch
		--          path = path you switched to
		--          prev_path = previous worktree path
		--      Create
		--          path = path where worktree created
		--          branch = branch name
		--          upstream = upstream remote name
		--      Delete
		--          path = path where worktree deleted

		Worktree.on_tree_change(function(op, metadata)
			if op == Worktree.Operations.Switch then
				print("Switched from " .. metadata.prev_path .. " to " .. metadata.path)
			end
		end)

		-- @todo
		-- Worktree.on_tree_change(function(op, path, upstream)
		-- if op == Worktree.Operations.Create then
		--     -- Job:new({
		--     --     "npm","install"
		--     -- })
		--     print("Created new worktree" .. metadata.path)
		-- end
		-- end)
	end,
}
