require("git").setup({
	keymaps = {
		-- Open blame window
		blame = ";gb",
		-- Close blame window
		quit_blame = "q",
		-- Open blame commit
		blame_commit = "<CR>",
		-- Open file/folder in git repository
		browse = ";go",
		-- Open pull request of the current branch
		open_pull_request = ";gp",
		-- Create a pull request with the target branch is set in the `target_branch` option
		create_pull_request = ";gn",
		-- Opens a new diff that compares against the current index
		diff = ";gd",
		-- Close git diff
		diff_close = ";gD",
		-- Revert to the specific commit
		revert = ";gr",
		-- Revert the current file to the specific commit
		revert_file = ";gR",
	},
})
