-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = "tokyonight_moon"
config.font = wezterm.font("FiraMono Nerd Font")
config.window_close_confirmation = "NeverPrompt"
local launch_menu = {}

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	-- Launch Git Bash as a login + interactive shell (-l -i). Without -l, MSYS's
	-- /etc/profile never runs, so /usr/bin (uname, etc.) is absent from PATH and
	-- os_env's `uname -s` fails on startup with "uname: command not found".
	config.default_prog = { "C:/Program Files/Git/bin/bash.exe", "-l", "-i" }
	table.insert(launch_menu, {
		label = "PowerShell",
		args = { "powershell.exe", "-NoLogo" },
	})
end

config.launch_menu = launch_menu

-- and finally, return the configuration to wezterm
return config
