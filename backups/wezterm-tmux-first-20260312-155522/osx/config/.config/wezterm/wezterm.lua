local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

-- tmux prefix is Ctrl+Space, which is ASCII NUL (\x00) on the PTY.
local function tmux_prefix(sequence)
  return act.SendString("\x00" .. sequence)
end

local function tmux_command(command)
  return act.SendString("\x00:" .. command .. "\r")
end

local builtin_schemes = wezterm.get_builtin_color_schemes()
if builtin_schemes["Tokyo Night Storm"] then
  config.color_scheme = "Tokyo Night Storm"
elseif builtin_schemes["Catppuccin Mocha"] then
  config.color_scheme = "Catppuccin Mocha"
else
  config.colors = {
    foreground = "#e8ede9",
    background = "#0a0f0c",
    cursor_bg = "#5ec4a0",
    cursor_fg = "#0a0f0c",
    selection_bg = "#27362f",
    selection_fg = "#e8ede9",
  }
end

config.default_prog = {
  os.getenv("SHELL") or "/bin/zsh",
  "-l",
  "-c",
  "exec tmux new-session -A -s main",
}

config.font = wezterm.font_with_fallback({
  "JetBrainsMono Nerd Font Mono",
  "JetBrains Mono",
  "Symbols Nerd Font Mono",
  "Menlo",
})
config.font_size = 14.0
config.line_height = 1.05
config.window_padding = {
  left = 12,
  right = 12,
  top = 10,
  bottom = 10,
}

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.window_decorations = "RESIZE"
config.macos_window_background_blur = 20
config.native_macos_fullscreen_mode = true
config.automatically_reload_config = true

config.keys = {
  { key = "c", mods = "CMD", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "CMD", action = act.PasteFrom("Clipboard") },

  -- Keep Ghostty muscle-memory, but route to tmux-native commands.
  { key = "d", mods = "CMD", action = tmux_prefix("%") },
  {
    key = "d",
    mods = "CMD|SHIFT",
    action = tmux_prefix('"'),
  },
  { key = "w", mods = "CMD", action = tmux_command("kill-pane") },
  { key = "t", mods = "CMD", action = tmux_prefix("c") },
  { key = "[", mods = "CMD|SHIFT", action = tmux_prefix("p") },
  { key = "]", mods = "CMD|SHIFT", action = tmux_prefix("n") },

  -- Keep macOS-style behavior for new terminal windows and zoom.
  { key = "n", mods = "CMD", action = act.SpawnWindow },
  { key = "=", mods = "CMD", action = act.IncreaseFontSize },
  { key = "-", mods = "CMD", action = act.DecreaseFontSize },
  { key = "0", mods = "CMD", action = act.ResetFontSize },

  -- Shift+Enter sends ESC+CR for Claude Code accept behavior.
  { key = "Enter", mods = "SHIFT", action = act.SendString("\x1b\r") },
}

return config
