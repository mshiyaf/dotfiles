local wezterm = require("wezterm")

local theme = wezterm.plugin.require("https://github.com/neapsix/wezterm").main

local window_padding = {
	left = 5,
	right = 5,
	top = 5,
	bottom = 5,
}

return {
	disable_default_key_bindings = false,

	font = wezterm.font("JetBrainsMono Nerd Font"),
	font_size = 10,

	use_fancy_tab_bar = true,
	enable_tab_bar = false,
	window_decorations = "RESIZE",
	window_padding = window_padding,
	window_background_opacity = 0,
	win32_system_backdrop = "Mica",

	clean_exit_codes = { 130 },
	audible_bell = "Disabled",
	initial_rows = 25,
	initial_cols = 80,
	cursor_thickness = "1pt",

	colors = theme.colors(),
	-- window_frame = theme.window_frame(),

	default_domain = "WSL:Ubuntu",
}
