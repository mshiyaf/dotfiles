return {
	"mfussenegger/nvim-dap",
	"leoluz/nvim-dap-go",
	"rcarriga/nvim-dap-ui",
	"nvim-telescope/telescope-dap.nvim",
	-- "theHamsta/nvim-dap-virtual-text",
	"mxsdev/nvim-dap-vscode-js",
	"microsoft/vscode-js-debug",
	config = function()
		require("dapui").setup()

		require("dap-vscode-js").setup({
			-- debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
			-- debugger_cmd = { "js-debug-adapter" },
			adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
		})

		local dap = require("dap")
		require("dap-go").setup()

		for _, language in ipairs({ "typescript", "javascript" }) do
			dap.configurations[language] = {
				{
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch file",
						program = "${file}",
						cwd = "${workspaceFolder}",
					},
					{
						type = "pwa-node",
						request = "attach",
						name = "Attach",
						processId = require("dap.utils").pick_process,
						cwd = "${workspaceFolder}",
					},
				},
			}
		end

		vim.keymap.set("n", "<leader>da", function()
			print("attaching")
			dap.run({
				name = "Attach to node terminal",
				type = "pwa-node",
				request = "attach",
				address = "127.0.0.1",
				port = 9229,
				cwd = "${workspaceFolder}",
				localRoot = vim.fn.getcwd(),
				sourceMaps = true,
				protocol = "inspector",
				skipFiles = { "<node_internals>/**/*.js", "node_modules/**" },
			})
		end)

		-- --
		-- vim.keymap.set("n", "<leader>dl", function()
		-- 	print("launching")
		-- 	dap.run({
		-- 		type = "pwa-node",
		-- 		name = "Run Script: dev",
		-- 		request = "launch",
		-- 		cwd = "${workspaceFolder}",
		-- 		command = "npm run dev",
		--         console = "integratedTerminal",
		-- 		skipFiles = { "<node_internals>/**/*.js", "node_modules/**" },
		-- 	})
		-- end)
	end,
}
