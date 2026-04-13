local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

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
config.native_macos_fullscreen_mode = true
config.automatically_reload_config = true

wezterm.on("update-right-status", function(window, _)
  local workspace = window:active_workspace()
  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#607068" } },
    { Text = "workspace " },
    { Foreground = { Color = "#5ec4a0" } },
    { Text = workspace },
    { Text = " " },
  }))
end)

local function pane_cwd_path(pane)
  local cwd = pane:get_current_working_dir()
  if not cwd then
    return nil
  end

  if type(cwd) == "table" or type(cwd) == "userdata" then
    if cwd.scheme == "file" and cwd.file_path then
      return cwd.file_path
    end
    return nil
  end

  return cwd
end

local function split_in_current_cwd(direction)
  return wezterm.action_callback(function(_, pane)
    local split_opts = {
      direction = direction,
    }

    local cwd = pane_cwd_path(pane)
    if cwd then
      split_opts.cwd = cwd
    end

    pane:split(split_opts)
  end)
end

config.keys = {
  { key = "c", mods = "CMD", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "CMD", action = act.PasteFrom("Clipboard") },

  -- Keep Ghostty muscle-memory, but use WezTerm-native panes/tabs.
  {
    key = "d",
    mods = "CMD",
    action = split_in_current_cwd("Right"),
  },
  {
    key = "d",
    mods = "CMD|SHIFT",
    action = split_in_current_cwd("Bottom"),
  },
  {
    key = "w",
    mods = "CMD",
    action = act.CloseCurrentPane({ confirm = false }),
  },
  { key = "t", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "[", mods = "CMD|SHIFT", action = act.ActivateTabRelative(-1) },
  { key = "]", mods = "CMD|SHIFT", action = act.ActivateTabRelative(1) },
  {
    key = "l",
    mods = "CMD|SHIFT",
    action = act.ShowLauncherArgs({
      flags = "FUZZY|TABS|WORKSPACES|LAUNCH_MENU_ITEMS",
    }),
  },
  {
    key = "p",
    mods = "CMD|SHIFT",
    action = act.PaneSelect,
  },

  -- Keep macOS-style behavior for new terminal windows and zoom.
  { key = "n", mods = "CMD", action = act.SpawnWindow },
  { key = "=", mods = "CMD", action = act.IncreaseFontSize },
  { key = "-", mods = "CMD", action = act.DecreaseFontSize },
  { key = "0", mods = "CMD", action = act.ResetFontSize },

  -- Shift+Enter sends ESC+CR for Claude Code accept behavior.
  { key = "Enter", mods = "SHIFT", action = act.SendString("\x1b\r") },
}

return config
