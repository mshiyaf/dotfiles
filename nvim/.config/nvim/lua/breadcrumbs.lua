local M = {}

M.config = {
	active = true,
	options = {
		icons = {
			Array = " ",
			Boolean = "蘒",
			Class = " ",
			Color = " ",
			Constant = " ",
			Constructor = " ",
			Enum = " ",
			EnumMember = " ",
			Event = " ",
			Field = " ",
			File = " ",
			Folder = " ",
			Function = " ",
			Interface = " ",
			Key = " ",
			Keyword = " ",
			Method = " ",
			Module = " ",
			Namespace = " ",
			Null = "ﳠ ",
			Number = " ",
			Object = " ",
			Operator = " ",
			Package = " ",
			Property = " ",
			Reference = " ",
			Snippet = " ",
			String = " ",
			Struct = " ",
			Text = " ",
			TypeParameter = " ",
			Unit = " ",
			Value = " ",
			Variable = " ",
		},
		highlight = true,
		separator = " > ",
		depth_limit = 0,
		depth_limit_indicator = "..",
	},
}

M.setup = function()
	local status_ok, navic = pcall(require, "nvim-navic")
	if not status_ok then
		return
	end

	M.create_winbar()
	navic.setup(M.config.options)
end

M.winbar_filetype_exclude = {
	"help",
	"startify",
	"dashboard",
	"packer",
	"neo-tree",
	"neogitstatus",
	"NvimTree",
	"Trouble",
	"alpha",
	"lir",
	"Outline",
	"spectre_panel",
	"toggleterm",
	"DressingSelect",
	"Jaq",
	"harpoon",
	"dap-repl",
	"dap-terminal",
	"dapui_console",
	"lab",
	"Markdown",
	"",
}

M.get_filename = function()
	local filename = vim.fn.expand("%:t")
	local extension = vim.fn.expand("%:e")
	local f = {}
	function f.isempty(s)
		return s == nil or s == ""
	end

	if not f.isempty(filename) then
		local file_icon, file_icon_color =
			require("nvim-web-devicons").get_icon_color(filename, extension, { default = true })

		local hl_group = "FileIconColor" .. extension

		vim.api.nvim_set_hl(0, hl_group, { fg = file_icon_color })
		if f.isempty(file_icon) then
			file_icon = M.config.options.icons.File
		end

		local navic_text = vim.api.nvim_get_hl_by_name("Normal", true)
		vim.api.nvim_set_hl(0, "Winbar", { fg = navic_text.foreground })

		return " " .. "%#" .. hl_group .. "#" .. file_icon .. "%*" .. " " .. "%#Winbar#" .. filename .. "%*"
	end
end

local excludes = function()
	if vim.tbl_contains(M.winbar_filetype_exclude, vim.bo.filetype) then
		return true
	end
	return false
end

local get_gps = function()
	local f = {}
	function f.isempty(s)
		return s == nil or s == ""
	end

	local status_gps_ok, gps = pcall(require, "nvim-navic")
	if not status_gps_ok then
		return ""
	end

	local status_ok, gps_location = pcall(gps.get_location, {})
	if not status_ok then
		return ""
	end

	if not gps.is_available() or gps_location == "error" then
		return ""
	end

	if not f.isempty(gps_location) then
		return ">" .. " " .. gps_location
	else
		return ""
	end
end

M.get_winbar = function()
	if excludes() then
		return
	end

	local f = {}
	function f.isempty(s)
		return s == nil or s == ""
	end

	function f.get_buf_option(opt)
		local status_ok, buf_option = pcall(vim.api.nvim_buf_get_option, 0, opt)
		if not status_ok then
			return nil
		else
			return buf_option
		end
	end

	local value = M.get_filename()

	local gps_added = false
	if not f.isempty(value) then
		local gps_value = get_gps()
		value = value .. " " .. gps_value
		if not f.isempty(gps_value) then
			gps_added = true
		end
	end

	if not f.isempty(value) and f.get_buf_option("mod") then
		local mod = "%#LspCodeLens#" .. " " .. "%*"
		if gps_added then
			value = value .. " " .. mod
		else
			value = value .. mod
		end
	end

	local num_tabs = #vim.api.nvim_list_tabpages()

	if num_tabs > 1 and not f.isempty(value) then
		local tabpage_number = tostring(vim.api.nvim_tabpage_get_number(0))
		value = value .. "%=" .. tabpage_number .. "/" .. tostring(num_tabs)
	end

	local status_ok, _ = pcall(vim.api.nvim_set_option_value, "winbar", value, { scope = "local" })
	if not status_ok then
		return
	end
end

M.create_winbar = function()
	vim.api.nvim_create_augroup("_winbar", {})
	if vim.fn.has("nvim-0.8") == 1 then
		vim.api.nvim_create_autocmd(
			{ "CursorMoved", "CursorHold", "BufWinEnter", "BufFilePost", "InsertEnter", "BufWritePost", "TabClosed" },
			{
				group = "_winbar",
				callback = function()
					local status_ok, _ = pcall(vim.api.nvim_buf_get_var, 0, "lsp_floating_window")
					if not status_ok then
						M.get_winbar()
					end
				end,
			}
		)
	end
end

return M
