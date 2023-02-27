local wezterm = require 'wezterm'

local window_padding = {
	left = 5,
	right = 5,
	top = 5,
	bottom = 5,
}

return {
	disable_default_key_bindings = false,
    font = wezterm.font 'CaskaydiaCove Nerd Font',
	font_size = 14,
	use_fancy_tab_bar = true,
	hide_tab_bar_if_only_one_tab = true,
	tab_max_width = 50,

	window_decorations = "RESIZE",
	window_padding = window_padding,
	color_scheme = "Catppuccin Mocha", -- or Macchiato, Frappe, Latte
	clean_exit_codes = { 130 },
	audible_bell = "Disabled",
	initial_rows = 25,
	initial_cols = 80,
	cursor_thickness = "2pt",
}
