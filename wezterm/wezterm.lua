-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

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

-- Terminator-style keybindings. WezTerm's split naming is the inverse of
-- Terminator's: Terminator's "split horizontally" (Ctrl+Shift+O) puts the new
-- pane *below* — that's WezTerm's SplitVertical; "split vertically"
-- (Ctrl+Shift+E) puts it to the *right* — that's WezTerm's SplitHorizontal.
config.keys = {
	-- Splits
	{ key = "o", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "e", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

	-- Focus panes (vim hjkl instead of Terminator's Alt+arrows)
	{ key = "h", mods = "ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "ALT", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "ALT", action = act.ActivatePaneDirection("Right") },
	{ key = "n", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Next") },
	{ key = "p", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Prev") },

	-- Resize panes (vim hjkl; Ctrl+Shift+<letter> never reaches terminal apps)
	{ key = "h", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Left", 1 }) },
	{ key = "j", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Down", 1 }) },
	{ key = "k", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Up", 1 }) },
	{ key = "l", mods = "CTRL|SHIFT", action = act.AdjustPaneSize({ "Right", 1 }) },

	-- Close pane / quit / toggle maximize
	{ key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "q", mods = "CTRL|SHIFT", action = act.QuitApplication },
	{ key = "x", mods = "CTRL|SHIFT", action = act.TogglePaneZoomState },

	-- Tabs
	{ key = "t", mods = "CTRL|SHIFT", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "PageUp", mods = "CTRL", action = act.ActivateTabRelative(-1) },
	{ key = "PageDown", mods = "CTRL", action = act.ActivateTabRelative(1) },
	{ key = "PageUp", mods = "CTRL|SHIFT", action = act.MoveTabRelative(-1) },
	{ key = "PageDown", mods = "CTRL|SHIFT", action = act.MoveTabRelative(1) },

	-- Rotate panes. Terminator uses Super+R, but Windows reserves the Win key at
	-- the OS level, so use Ctrl+Shift+R instead (this overrides WezTerm's manual
	-- reload, which is redundant: automatically_reload_config reloads on save).
	-- Alt adds the reverse direction.
	{ key = "r", mods = "CTRL|SHIFT", action = act.RotatePanes("Clockwise") },
	{ key = "r", mods = "CTRL|SHIFT|ALT", action = act.RotatePanes("CounterClockwise") },

	-- Copy / paste
	{ key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

	-- Search scrollback
	{ key = "f", mods = "CTRL|SHIFT", action = act.Search("CurrentSelectionOrEmptyString") },

	-- Font size
	{ key = "=", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "+", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = act.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = act.ResetFontSize },

	-- Fullscreen
	{ key = "F11", mods = "NONE", action = act.ToggleFullScreen },
}

-- and finally, return the configuration to wezterm
return config
