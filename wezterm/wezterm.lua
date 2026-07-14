local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

config.color_scheme = "tokyonight_moon"
config.font = wezterm.font("FiraMono Nerd Font")
config.window_close_confirmation = "NeverPrompt"

-- Make the active pane stand out: dim + desaturate inactive panes well below
-- WezTerm's subtle defaults (saturation 0.9, brightness 0.8) so the focused
-- pane is obvious at a glance when several are open.
config.inactive_pane_hsb = {
	saturation = 0.8,
	brightness = 0.6,
}
local launch_menu = {}

if wezterm.target_triple:find("windows") then
	-- Launch Git Bash as a login + interactive shell (-l -i). Without -l, MSYS's
	-- /etc/profile never runs, so /usr/bin (uname, etc.) is absent from PATH and
	-- shellenv's `uname -s` fails on startup with "uname: command not found".
	config.default_prog = { "C:/Program Files/Git/bin/bash.exe", "-l", "-i" }
	table.insert(launch_menu, {
		label = "PowerShell",
		args = { "powershell.exe", "-NoLogo" },
	})
end

config.launch_menu = launch_menu

config.keys = {
	-- Only custom/overriding binds; WezTerm defaults (copy, paste, tabs, font
	-- size, search, fullscreen) are assumed.

	-- Splits
	{ key = "e", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "o", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

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

	-- Rotate panes. Terminator uses Super+R, but Windows reserves the Win key at
	-- the OS level, so use Ctrl+Shift+R instead (this overrides WezTerm's manual
	-- reload, which is redundant: automatically_reload_config reloads on save).
	-- Alt adds the reverse direction.
	{ key = "r", mods = "CTRL|SHIFT", action = act.RotatePanes("Clockwise") },
	{ key = "r", mods = "CTRL|SHIFT|ALT", action = act.RotatePanes("CounterClockwise") },

	-- `+` is Shift+`=`; bind it by produced character (mapped:) and both with and
	-- without SHIFT — a plain `key = "+"` matches by physical position and silently
	-- fails. WezTerm's default Ctrl+= handles the base increase.
	{ key = "mapped:+", mods = "CTRL", action = act.IncreaseFontSize },
	{ key = "mapped:+", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
}

-- ── WezTerm-as-tmux ─────────────────────────────────────────────────────────
-- WezTerm does its own multiplexing on every machine. The command layer uses
-- prefix Ctrl+Space, distinct from tmux's Ctrl+b, so the two never collide: you
-- can still run tmux inside a WezTerm pane (its Ctrl+b passes straight through,
-- locally or over SSH) if you want.
--
-- Persistence is opt-in, like tmux. A plain `wezterm` launch is an independent,
-- ephemeral terminal on the in-process local domain — close the window and its
-- panes are gone. The `unix` domain below defines a background mux server but
-- nothing auto-connects to it: run `wezterm connect unix` for a persistent
-- session in a new window (the `tmux attach` equivalent), `wezterm connect
-- --new-tab unix` to attach as a tab in the active window, or pick the `unix`
-- domain from the leader launcher (Ctrl+Space s). The server is spawned on first
-- connect and survives closing the window, but not a reboot.
config.unix_domains = { { name = "unix" } }

-- Prefix. Ctrl+Space avoids clobbering readline/Neovim Ctrl-letter binds and
-- leaves Ctrl+b free for tmux on remote servers.
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 2000 }

config.key_tables = {
	-- Ctrl+Space r → sticky resize; hjkl resize, Esc/q exit
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 2 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 2 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "q", action = "PopKeyTable" },
	},
}

-- tmux command layer (prefix = Ctrl+Space). Keys mirror tmux defaults; see the
-- split note above for why % / " map to the inverse WezTerm split names.
local L = "LEADER"
local tmux_keys = {
	-- send a literal Ctrl+Space through (tmux: prefix prefix)
	{ key = "Space", mods = "LEADER|CTRL", action = act.SendKey({ key = "Space", mods = "CTRL" }) },

	-- Panes
	{ key = "o", mods = L, action = act.ActivatePaneDirection("Next") },
	{ key = "x", mods = L, action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "z", mods = L, action = act.TogglePaneZoomState },
	{ key = "Space", mods = L, action = act.RotatePanes("Clockwise") },
	{
		key = "r",
		mods = L,
		action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false, timeout_milliseconds = 1500 }),
	},
	{ key = "h", mods = L, action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = L, action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = L, action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = L, action = act.ActivatePaneDirection("Right") },
	{ key = "LeftArrow", mods = L, action = act.ActivatePaneDirection("Left") },
	{ key = "DownArrow", mods = L, action = act.ActivatePaneDirection("Down") },
	{ key = "UpArrow", mods = L, action = act.ActivatePaneDirection("Up") },
	{ key = "RightArrow", mods = L, action = act.ActivatePaneDirection("Right") },

	-- Windows (≈ WezTerm tabs)
	{ key = "c", mods = L, action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "n", mods = L, action = act.ActivateTabRelative(1) },
	{ key = "p", mods = L, action = act.ActivateTabRelative(-1) },
	{ key = "w", mods = L, action = act.ShowTabNavigator },

	-- Sessions / detach (only meaningful with persistence on, harmless otherwise)
	{ key = "d", mods = L, action = act.DetachDomain("CurrentPaneDomain") },
	{ key = "s", mods = L, action = act.ShowLauncherArgs({ flags = "FUZZY|DOMAINS" }) },
}

-- Ctrl+Space <n> → window/tab n (tmux base index 0)
for i = 0, 9 do
	table.insert(tmux_keys, { key = tostring(i), mods = L, action = act.ActivateTab(i) })
end

-- Symbol keys must use the `mapped:` prefix so WezTerm matches them by the
-- character produced rather than by physical key position; the plain forms
-- (key = "%") silently fail to match. Shift-produced symbols (% " & :) are bound
-- both with and without SHIFT, since WezTerm versions differ on whether the
-- shift used to type them is reported in the event mods.
local function leader_symbol(key, shifted, action)
	table.insert(tmux_keys, { key = "mapped:" .. key, mods = L, action = action })
	if shifted then
		table.insert(tmux_keys, { key = "mapped:" .. key, mods = "LEADER|SHIFT", action = action })
	end
end

leader_symbol("%", true, act.SplitHorizontal({ domain = "CurrentPaneDomain" })) -- split right
leader_symbol('"', true, act.SplitVertical({ domain = "CurrentPaneDomain" })) -- split below
leader_symbol("&", true, act.CloseCurrentTab({ confirm = true })) -- kill window
leader_symbol(":", true, act.ActivateCommandPalette) -- command prompt
leader_symbol("[", false, act.ActivateCopyMode) -- copy mode
leader_symbol("]", false, act.PasteFrom("Clipboard")) -- paste
leader_symbol(
	",",
	false,
	act.PromptInputLine({ -- rename window/tab
		description = "Rename tab",
		action = wezterm.action_callback(function(window, _, line)
			if line and #line > 0 then
				window:active_tab():set_title(line)
			end
		end),
	})
)

for _, k in ipairs(tmux_keys) do
	table.insert(config.keys, k)
end

return config
