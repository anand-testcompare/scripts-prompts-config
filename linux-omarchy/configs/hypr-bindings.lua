-- Application bindings.
o.bind("SUPER + RETURN", "Terminal", { omarchy = "terminal" })
o.bind("SUPER + ALT + RETURN", "Tmux", { omarchy = "terminal-tmux" })
o.bind("SUPER + SHIFT + RETURN", "Browser", { omarchy = "browser" })
o.bind("SUPER + SHIFT + F", "File manager", { omarchy = "nautilus" })
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", { omarchy = "nautilus-cwd" })
o.bind("SUPER + SHIFT + B", "Browser", { omarchy = "browser" })
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", { omarchy = "browser --private" })
o.bind("SUPER + SHIFT + M", "Music", { omarchy = "or-focus spotify" })
o.bind("SUPER + SHIFT + ALT + M", "Music TUI", { tui = "cliamp", focus = true })
o.bind("SUPER + SHIFT + N", "Editor", { omarchy = "editor" })
o.bind("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
o.bind("SUPER + SHIFT + G", "Signal", { launch = "signal-desktop", focus = "^signal$" })
o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
o.bind("SUPER + SHIFT + W", "Typora", { launch = "typora --enable-wayland-ime" })
o.bind("SUPER + SHIFT + SLASH", "Passwords", { launch = "1password" })

-- Web app bindings.
o.bind("SUPER + SHIFT + A", "ChatGPT", { webapp = "https://chatgpt.com" })
o.bind("SUPER + SHIFT + ALT + A", "Grok", { webapp = "https://grok.com" })
o.bind("SUPER + SHIFT + C", "Calendar", { webapp = "https://app.hey.com/calendar/weeks/" })
o.bind("SUPER + SHIFT + E", "Email", { webapp = "https://app.hey.com" })
o.bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/" })
o.bind("SUPER + SHIFT + ALT + G", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })
o.bind("SUPER + SHIFT + CTRL + G", "Google Messages", { webapp = "https://messages.google.com/web/conversations", focus = true })
o.bind("SUPER + SHIFT + P", "Google Photos", { webapp = "https://photos.google.com/", focus = true })
o.bind("SUPER + SHIFT + S", "Google Maps", { webapp = "https://maps.google.com/", focus = true })
o.bind("SUPER + SHIFT + X", "X", { webapp = "https://x.com/" })
o.bind("SUPER + SHIFT + ALT + X", "X Post", { webapp = "https://x.com/compose/post" })

-- Add extra bindings below.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Reapplied from pre-Lua Omarchy config backup: bindings.conf.bak.1780811536.

-- Speech-to-text.
hl.unbind("SUPER + CTRL + X")
o.bind("SUPER + ALT + D", "Speech-to-text", "/usr/lib/hyprwhspr/config/hyprland/hyprwhspr-tray.sh record")

-- Remap close window from Super+W to Super+Q (so Cmd+W works in apps).
hl.unbind("SUPER + W")
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- Override default clipboard binds to avoid conflicts with xremap.
hl.unbind("SUPER + C")
hl.unbind("SUPER + V")

-- Ghostty-aware shortcuts (checks focused window, routes appropriately).
o.bind("SUPER + W", "Close (smart)", "~/.local/bin/ghostty-or-universal close")
o.bind("SUPER + C", "Copy (smart)", "~/.local/bin/ghostty-or-universal copy")
o.bind("SUPER + V", "Paste (smart)", "~/.local/bin/ghostty-or-universal paste")
hl.unbind("SUPER + T")
o.bind("SUPER + T", "New tab (smart)", "~/.local/bin/ghostty-or-universal new-tab")
o.bind("SUPER + N", "New window (smart)", "~/.local/bin/ghostty-or-universal new-window")

-- Screenshot shortcuts.
o.bind("CTRL + SHIFT + code:12", "Screenshot fullscreen to clipboard and file", "omarchy-capture-screenshot fullscreen")
o.bind("CTRL + SHIFT + code:13", "Screenshot region to clipboard and file", "omarchy-capture-screenshot region")
o.bind("CTRL + SHIFT + code:14", "Screenshot smart to clipboard and file", "omarchy-capture-screenshot smart")

-- Move window in direction (within workspace, then to monitor if at edge).
hl.unbind("SUPER + CTRL + LEFT")
hl.unbind("SUPER + CTRL + RIGHT")
o.bind("SUPER + CTRL + LEFT", "Move window left", "~/.local/bin/hypr-move-window l")
o.bind("SUPER + CTRL + RIGHT", "Move window right", "~/.local/bin/hypr-move-window r")
o.bind("SUPER + CTRL + UP", "Move window up", "~/.local/bin/hypr-move-window u")
o.bind("SUPER + CTRL + DOWN", "Move window down", "~/.local/bin/hypr-move-window d")

-- DP-1 monitor scale presets (F13/F14/F15 keys).
local function set_dp1_scale(scale)
  hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", scale = scale })
end

o.bind("XF86Tools", "DP-1 scale 1.666667", function()
  set_dp1_scale(1.666667)
end)
o.bind("XF86Launch5", "DP-1 scale 1.875", function()
  set_dp1_scale(1.875)
end)
o.bind("XF86Launch6", "DP-1 scale 2", function()
  set_dp1_scale(2)
end)

-- Also bind literal F13/F14/F15 (in case your keyboard sends those).
o.bind("F13", "DP-1 scale 1.666667", function()
  set_dp1_scale(1.666667)
end)
o.bind("F14", "DP-1 scale 1.875", function()
  set_dp1_scale(1.875)
end)
o.bind("F15", "DP-1 scale 2", function()
  set_dp1_scale(2)
end)

-- Disable Omarchy's default SUPER+scroll workspace cycling. This keeps
-- accidental wheel/touchpad input from switching workspaces while preserving
-- explicit SUPER+number workspace navigation.
hl.unbind("SUPER + mouse_down")
hl.unbind("SUPER + mouse_up")

-- Reduce scroll delay for responsive mouse wheel zoom.
hl.config({
  binds = {
    scroll_event_delay = 50,
  },
})

-- Zoom controls (keyboard with SUPER CTRL).
local function set_cursor_zoom(zoom)
  if zoom < 1 then
    zoom = 1
  end
  hl.config({ cursor = { zoom_factor = zoom } })
end

local function multiply_cursor_zoom(multiplier)
  set_cursor_zoom((hl.get_config("cursor.zoom_factor") or 1) * multiplier)
end

o.bind("SUPER + CTRL + equal", "Zoom in", function()
  multiply_cursor_zoom(1.1)
end, { repeating = true })
o.bind("SUPER + CTRL + minus", "Zoom out", function()
  multiply_cursor_zoom(0.9)
end, { repeating = true })
o.bind("SUPER + CTRL + KP_ADD", "Zoom in", function()
  multiply_cursor_zoom(1.1)
end, { repeating = true })
o.bind("SUPER + CTRL + KP_SUBTRACT", "Zoom out", function()
  multiply_cursor_zoom(0.9)
end, { repeating = true })

-- Zoom controls (mouse wheel with SUPER CTRL - avoids conflict with workspace scroll).
o.bind("SUPER + CTRL + mouse_down", "Zoom in", function()
  multiply_cursor_zoom(1.1)
end)
o.bind("SUPER + CTRL + mouse_up", "Zoom out", function()
  multiply_cursor_zoom(0.9)
end)

-- Zoom reset.
o.bind("SUPER + CTRL + 0", "Zoom reset", function()
  set_cursor_zoom(1)
end)
o.bind("SUPER + CTRL + SHIFT + mouse_up", "Zoom reset", function()
  set_cursor_zoom(1)
end)
o.bind("SUPER + CTRL + SHIFT + mouse_down", "Zoom reset", function()
  set_cursor_zoom(1)
end)

-- Overwrite existing bindings with hl.unbind() first if needed.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, { omarchy = "walker -m symbols" })
