local Remap = require("keymap")
local nnoremap = Remap.nnoremap

local status, telescope = pcall(require, "telescope")
if not status then
	return
end
local actions = require("telescope.actions")
local builtin = require("telescope.builtin")

local function telescope_buffer_dir()
	return vim.fn.expand("%:p:h")
end

local fb_actions = require("telescope").extensions.file_browser.actions

telescope.setup({
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
	extensions = {
		file_browser = {
			-- disables netrw and use telescope-file-browser in its place
			sorting_strategy = "ascending",
			layout_strategy = "horizontal",
			layout_config = {
				horizontal = {
					prompt_position = "top",
					width = 65,
				},
			},
			hijack_netrw = true,
			hidden = true,
			cwd = telescope_buffer_dir(),
			respect_gitignore = false,
			grouped = true,
			previewer = false,
			initial_mode = "normal",
			mappings = {
				-- your custom insert mode mappings
				["i"] = {
					["<C-w>"] = function()
						vim.cmd("normal vbd")
					end,
				},
				["n"] = {
					-- your custom normal mode mappings
					["N"] = fb_actions.create,
					["h"] = fb_actions.goto_parent_dir,
					["."] = fb_actions.toggle_hidden,
					["/"] = function()
						vim.cmd("startinsert")
					end,
				},
			},
		},
	},
})

telescope.load_extension("file_browser")

vim.keymap.set("n", "<leader>f", function()
	builtin.find_files({
		hidden = true,
	})
end)
vim.keymap.set("n", "<leader>g", function()
	builtin.live_grep({
		additional_args = function()
			return { "--hidden" }
		end,
	})
end)
vim.keymap.set("n", "<leader>b", function()
	builtin.buffers()
end)
vim.keymap.set("n", ";;", function()
	builtin.resume()
end)
vim.keymap.set("n", "-", function()
	telescope.extensions.file_browser.file_browser({
		path = "%:p:h",
		cwd = telescope_buffer_dir(),
		respect_gitignore = false,
		hidden = true,
		grouped = true,
		previewer = false,
		initial_mode = "normal",
		layout_config = { height = 30 },
	})
end)

require("telescope").load_extension("git_worktree")

nnoremap("<leader>;", ":lua require('telescope').extensions.git_worktree.git_worktrees()<cr>")
nnoremap("<leader>cw", ":lua require('telescope').extensions.git_worktree.create_git_worktree()<cr>")
