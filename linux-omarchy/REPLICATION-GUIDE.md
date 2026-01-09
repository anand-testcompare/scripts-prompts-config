# Omarchy QoL Setup Replication Guide

This guide documents how to replicate the quality-of-life improvements made on top of base Omarchy.

---

## 1. Terminal QoL Tools

These tools provide autocomplete, better history, and smarter navigation.

### Install packages
```bash
sudo pacman -S zsh-autosuggestions zsh-fast-syntax-highlighting zsh-history-substring-search fzf eza bat zoxide atuin starship mise
```

### Add to ~/.zshrc
```bash
# Syntax highlighting, autosuggestions, history search
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# fzf integration (Ctrl+R for history, Ctrl+T for files, Alt+C for cd)
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# zoxide replaces cd (learns your frequently used directories)
eval "$(zoxide init zsh --cmd cd)"

# atuin for better shell history (syncs across machines)
eval "$(atuin init zsh)"

# starship prompt
eval "$(starship init zsh)"

# mise for language version management (replaces nvm, pyenv, etc.)
eval "$(mise activate zsh)"
```

### What each tool does:
| Tool | Purpose |
|------|---------|
| `zsh-autosuggestions` | Ghost text suggestions as you type (accept with →) |
| `zsh-fast-syntax-highlighting` | Colors commands as you type (red = invalid, green = valid) |
| `zsh-history-substring-search` | Up/Down arrows search history by what you've typed |
| `fzf` | Fuzzy finder: Ctrl+R (history), Ctrl+T (files), Alt+C (cd) |
| `zoxide` | Smart `cd` that learns your frequent directories |
| `atuin` | Synced shell history with full-text search |
| `starship` | Fast, customizable prompt |
| `mise` | Polyglot version manager (node, python, go, etc.) |

---

## 2. Useful Aliases

Add to `~/.zshrc`:

```bash
# Clipboard (macOS-style)
alias pbcopy='wl-copy'
alias pbpaste='wl-paste'

# Better ls (requires eza)
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'

# Better cat (requires bat)
alias cat='bat'

# Fuzzy file finder with preview
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git shortcuts
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

# Docker
alias d='docker'

# Nvim: `n` opens current dir, `n file` opens file
n() { if [ "$#" -eq 0 ]; then nvim .; else nvim "$@"; fi; }

# Open files like macOS
open() { xdg-open "$@" >/dev/null 2>&1 & }

# Compression helpers
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress="tar -xzf"

# Image/video processing (requires ffmpeg, imagemagick)
transcode-video-1080p() { ffmpeg -i $1 -vf scale=1920:1080 -c:v libx264 -preset fast -crf 23 -c:a copy ${1%.*}-1080p.mp4; }
transcode-video-4K() { ffmpeg -i $1 -c:v libx265 -preset slow -crf 24 -c:a aac -b:a 192k ${1%.*}-optimized.mp4; }
img2jpg() { img="$1"; shift; magick "$img" $@ -quality 95 -strip ${img%.*}-optimized.jpg; }
img2png() { img="$1"; shift; magick "$img" $@ -strip -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 -define png:exclude-chunk=all "${img%.*}-optimized.png"; }
```

---

## 3. Mac-Style Keybindings (xremap)

Makes Cmd+C/V/A/Z etc. work system-wide like macOS.

### Install xremap
```bash
yay -S xremap-wlroots-bin
```

### Set up uinput permissions
```bash
# Create uinput rules
echo 'KERNEL=="uinput", GROUP="input", MODE="0660"' | sudo tee /etc/udev/rules.d/99-uinput.rules
echo 'uinput' | sudo tee /etc/modules-load.d/uinput.conf

# Add user to input group
sudo usermod -aG input $USER

# Reboot or reload
sudo modprobe uinput
sudo udevadm control --reload-rules
```

### Create ~/.config/xremap/config.yml
```yaml
keymap:
  - name: Passthrough for Hyprland window management
    remap:
      Super_L-Alt_L-Left: Super_L-Alt_L-Left
      Super_L-Alt_L-Right: Super_L-Alt_L-Right
      Super_L-Alt_L-Tab: Super_L-Alt_L-Tab
      Super_L-Ctrl_L-Left: Super_L-Ctrl_L-Left
      Super_L-Ctrl_L-Right: Super_L-Ctrl_L-Right
      Super_L-Ctrl_L-Up: Super_L-Ctrl_L-Up
      Super_L-Ctrl_L-Down: Super_L-Ctrl_L-Down

  - name: Mac-like shortcuts for non-terminal apps
    application:
      not:
        - ghostty
        - kitty
        - alacritty
        - dev.zed.Zed
        - dev.zed.Zed-Preview
    remap:
      Super_L-a: Ctrl-a
      Super_L-c: Ctrl-c
      Super_L-v: Ctrl-v
      Super_L-x: Ctrl-x
      Super_L-z: Ctrl-z
      Super_L-Shift-z: Ctrl-y
      Super_L-t: Ctrl-t
      Super_L-w: Ctrl-w
      Super_L-Shift-t: Ctrl-Shift-t
      Super_L-l: Ctrl-l
      Super_L-f: Ctrl-f
      Super_L-Left: Home
      Super_L-Right: End
      Super_L-Up: Ctrl-Home
      Super_L-Down: Ctrl-End
      Super_L-o: Ctrl-o
      Super_L-n: Ctrl-n
      Super_L-p: Ctrl-p
      Super_L-r: Ctrl-r
      Super_L-equal: Ctrl-equal
      Super_L-minus: Ctrl-minus
      Super_L-0: Ctrl-0
```

### Autostart xremap (add to ~/.config/hypr/autostart.conf)
```bash
exec-once = xremap --device "YOUR_KEYBOARD_NAME" ~/.config/xremap/config.yml
```

Find your keyboard name with: `xremap --list-devices`

---

## 4. Hyprland Customizations

### Remap close window to Super+Q (so Cmd+W works in apps)

Add to `~/.config/hypr/bindings.conf`:
```bash
# Close window with Super+Q instead of Super+W
unbind = SUPER, W
bindd = SUPER, Q, Close window, killactive,
```

### Magnet-style window movement across monitors

Create `~/.local/bin/hypr-move-window`:
```bash
#!/bin/bash
# Move window in direction, crossing monitors when at edge

direction="$1"
window_info=$(hyprctl activewindow -j)
current_monitor_id=$(echo "$window_info" | jq -r '.monitor')
window_x=$(echo "$window_info" | jq -r '.at[0]')
window_y=$(echo "$window_info" | jq -r '.at[1]')

monitors=$(hyprctl monitors -j)
monitor_x=$(echo "$monitors" | jq -r ".[] | select(.id == $current_monitor_id) | .x")
monitor_y=$(echo "$monitors" | jq -r ".[] | select(.id == $current_monitor_id) | .y")

threshold=50

case "$direction" in
    l)
        if [ "$window_x" -lt "$threshold" ]; then
            target=$(echo "$monitors" | jq -r --argjson cx "$monitor_x" '[.[] | select(.x < $cx)] | sort_by(.x) | last | .name // empty')
            if [ -n "$target" ] && [ "$target" != "null" ]; then
                hyprctl dispatch movewindow mon:"$target"
                exit 0
            fi
        fi
        ;;
    r)
        hyprctl dispatch movewindoworgroup r
        sleep 0.05
        new_x=$(hyprctl activewindow -j | jq -r '.at[0]')
        if [ "$new_x" = "$window_x" ]; then
            target=$(echo "$monitors" | jq -r --argjson cx "$monitor_x" '[.[] | select(.x > $cx)] | sort_by(.x) | first | .name // empty')
            if [ -n "$target" ] && [ "$target" != "null" ]; then
                hyprctl dispatch movewindow mon:"$target"
                sleep 0.05
                hyprctl dispatch movewindoworgroup l
            fi
        fi
        exit 0
        ;;
    u)
        if [ "$window_y" -lt "$threshold" ]; then
            target=$(echo "$monitors" | jq -r --argjson cy "$monitor_y" '[.[] | select(.y < $cy)] | sort_by(.y) | last | .name // empty')
            if [ -n "$target" ] && [ "$target" != "null" ]; then
                hyprctl dispatch movewindow mon:"$target"
                exit 0
            fi
        fi
        ;;
    d)
        hyprctl dispatch movewindoworgroup d
        sleep 0.05
        new_y=$(hyprctl activewindow -j | jq -r '.at[1]')
        if [ "$new_y" = "$window_y" ]; then
            target=$(echo "$monitors" | jq -r --argjson cy "$monitor_y" '[.[] | select(.y > $cy)] | sort_by(.y) | first | .name // empty')
            if [ -n "$target" ] && [ "$target" != "null" ]; then
                hyprctl dispatch movewindow mon:"$target"
            fi
        fi
        exit 0
        ;;
esac

hyprctl dispatch movewindoworgroup "$direction"
```

Make it executable and add bindings:
```bash
chmod +x ~/.local/bin/hypr-move-window
```

Add to `~/.config/hypr/bindings.conf`:
```bash
bindd = SUPER CTRL, LEFT, Move window left, exec, ~/.local/bin/hypr-move-window l
bindd = SUPER CTRL, RIGHT, Move window right, exec, ~/.local/bin/hypr-move-window r
bindd = SUPER CTRL, UP, Move window up, exec, ~/.local/bin/hypr-move-window u
bindd = SUPER CTRL, DOWN, Move window down, exec, ~/.local/bin/hypr-move-window d
```

### Screen Zoom (Magnification)

Hyprland has built-in cursor zoom for accessibility. Add to `~/.config/hypr/looknfeel.conf`:
```bash
cursor {
    no_hardware_cursors = true  # Required for zoom to work
    zoom_rigid = true           # Zoom follows cursor rigidly
}
```

Add to `~/.config/hypr/bindings.conf`:
```bash
# Reduce scroll delay for responsive mouse wheel zoom
binds {
    scroll_event_delay = 50
}

# Zoom controls (keyboard with SUPER CTRL)
binde = SUPER CTRL, equal, exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float * 1.1')
binde = SUPER CTRL, minus, exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '(.float * 0.9) | if . < 1 then 1 else . end')
binde = SUPER CTRL, KP_ADD, exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float * 1.1')
binde = SUPER CTRL, KP_SUBTRACT, exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '(.float * 0.9) | if . < 1 then 1 else . end')

# Zoom controls (mouse wheel with SUPER CTRL - avoids conflict with workspace scroll)
bind = SUPER CTRL, mouse_down, exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float * 1.1')
bind = SUPER CTRL, mouse_up, exec, hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '(.float * 0.9) | if . < 1 then 1 else . end')

# Zoom reset
bind = SUPER CTRL, 0, exec, hyprctl -q keyword cursor:zoom_factor 1
bind = SUPER CTRL SHIFT, mouse_up, exec, hyprctl -q keyword cursor:zoom_factor 1
bind = SUPER CTRL SHIFT, mouse_down, exec, hyprctl -q keyword cursor:zoom_factor 1
```

**Notes:**
- Zoom only magnifies (values > 1.0). Values below 1.0 have no visual effect.
- Mouse scroll uses SUPER+CTRL (not just SUPER) because SUPER+scroll is already bound to workspace switching in Omarchy defaults.

### Monitor Scale Presets (4K displays)

For quick switching between display scales. Fractional scales must divide evenly into resolution.

For 3840x2160, valid scales include:
| Scale | Effective Resolution |
|-------|---------------------|
| 1.5 | 2560x1440 |
| 1.6 | 2400x1350 |
| 1.666667 | 2304x1296 |
| 1.875 | 2048x1152 |
| 2.0 | 1920x1080 |

Add to `~/.config/hypr/bindings.conf` (uses F13/F14/F15 on Keychron keyboards):
```bash
# DP-1 monitor scale presets (F13/F14/F15 keys)
bind = , XF86Tools, exec, hyprctl keyword monitor DP-1,preferred,auto,1.666667
bind = , XF86Launch5, exec, hyprctl keyword monitor DP-1,preferred,auto,1.875
bind = , XF86Launch6, exec, hyprctl keyword monitor DP-1,preferred,auto,2
```

**Note:** Keychron F13/F14/F15 send `XF86Tools`, `XF86Launch5`, `XF86Launch6`. Use `wev -f wl_keyboard:key` to find your keyboard's actual keycodes.

### Scratchpad Window Management

Omarchy includes a scratchpad (special workspace) with default bindings:
- `Super+S` - Toggle scratchpad visibility
- `Super+Alt+S` - Move window to scratchpad

To add a toggle that moves windows to/from scratchpad:

Create `~/.local/bin/toggle-scratchpad-window`:
```bash
#!/bin/bash
# Toggle window between scratchpad and previous workspace

workspace=$(hyprctl activewindow -j | jq -r '.workspace.name')

if [[ "$workspace" == "special:scratchpad" ]]; then
    # Move back to the most recent regular workspace
    hyprctl dispatch movetoworkspace e+0
else
    # Move to scratchpad
    hyprctl dispatch movetoworkspacesilent special:scratchpad
fi
```

Make it executable:
```bash
chmod +x ~/.local/bin/toggle-scratchpad-window
```

Add to `~/.config/hypr/hyprland.conf`:
```bash
# Toggle window to/from scratchpad
bind = SUPER SHIFT, S, exec, ~/.local/bin/toggle-scratchpad-window
```

Add visual indicator (teal border) for scratchpad windows in `~/.config/hypr/looknfeel.conf`:
```bash
# Teal border for scratchpad windows
windowrulev2 = bordercolor rgb(00b5b5), onworkspace:special:scratchpad
```

---

## 5. Voice Dictation (hyprwhspr)

hyprwhspr provides system-wide voice-to-text using Whisper.

### Install
```bash
yay -S hyprwhspr
sudo pacman -S python-rich
```

### Configure

Config file: `~/.config/hyprwhspr/config.json`
```json
{
  "primary_shortcut": "SUPER+SHIFT+D",
  "recording_mode": "toggle",
  "model": "base",
  "threads": 4,
  "language": null,
  "clipboard_behavior": false,
  "paste_mode": "ctrl_shift",
  "shift_paste": true,
  "transcription_backend": "rest-api",
  "rest_endpoint_url": "http://127.0.0.1:17980/transcribe",
  "audio_feedback": true
}
```

### Enable systemd service
```bash
systemctl --user enable --now hyprwhspr.service
```

### Usage
- `Super+Shift+D` - Toggle recording (press once to start, again to stop and transcribe)

---

## 7. Ghostty Terminal Config

Add to `~/.config/ghostty/config`:
```
# Font
font-family = "JetBrainsMono Nerd Font"
font-size = 9

# Mac-style keybindings
keybind = super+a=select_all
keybind = super+c=copy_to_clipboard
keybind = super+v=paste_from_clipboard
keybind = super+d=new_split:right
keybind = super+shift+d=new_split:down
keybind = super+w=close_surface
keybind = super+t=new_tab
keybind = super+n=new_window
keybind = super+shift+left_bracket=previous_tab
keybind = super+shift+right_bracket=next_tab
keybind = super+equal=increase_font_size:1
keybind = super+minus=decrease_font_size:1
keybind = super+zero=reset_font_size

# Shift+Enter sends escape sequence (for Claude Code accept)
keybind = shift+enter=text:\x1b\r
```

---

## 8. Zed Editor Keybindings

Create `~/.config/zed/keymap.json`:
```json
[
  {
    "bindings": {
      "super-a": "editor::SelectAll",
      "super-c": "editor::Copy",
      "super-v": "editor::Paste",
      "super-x": "editor::Cut",
      "super-z": "editor::Undo",
      "super-shift-z": "editor::Redo",
      "super-s": "workspace::Save",
      "super-w": "pane::CloseActiveItem",
      "super-t": "workspace::NewFile",
      "super-f": "buffer_search::Deploy",
      "super-p": "file_finder::Toggle",
      "super-shift-p": "command_palette::Toggle",
      "super-n": "workspace::NewWindow",
      "super-o": "workspace::Open",
      "super-d": "pane::SplitRight",
      "super-shift-d": "pane::SplitDown"
    }
  },
  {
    "context": "Terminal",
    "bindings": {
      "shift-enter": ["terminal::SendText", "\u001b\r"],
      "super-a": "terminal::SelectAll",
      "super-c": "terminal::Copy",
      "super-v": "terminal::Paste"
    }
  }
]
```

---

## 9. VS Code Keybindings

Create `~/.config/Code/User/keybindings.json`:
```json
[
    {
        "key": "shift+enter",
        "command": "workbench.action.terminal.sendSequence",
        "args": { "text": "\u001b\r" },
        "when": "terminalFocus"
    }
]
```

---

## 10. Neovim (LazyVim)

The setup is mostly default LazyVim. Only customization:

Edit `~/.config/nvim/lua/config/options.lua`:
```lua
vim.opt.relativenumber = false
```

---

## Summary Checklist

- [ ] Install terminal tools: `zsh-autosuggestions`, `zsh-fast-syntax-highlighting`, `zsh-history-substring-search`, `fzf`, `eza`, `bat`, `zoxide`, `atuin`, `starship`, `mise`
- [ ] Add tool initializations to `~/.zshrc`
- [ ] Add aliases to `~/.zshrc`
- [ ] Install `xremap-wlroots-bin` and set up uinput permissions
- [ ] Create xremap config and autostart
- [ ] Add Hyprland bindings (Super+Q close, window movement)
- [ ] Create hypr-move-window script
- [ ] Add Hyprland zoom controls (cursor section in looknfeel.conf, bindings)
- [ ] Add monitor scale presets (F13/F14/F15 for 4K scaling)
- [ ] Create toggle-scratchpad-window script and add Super+Shift+S binding
- [ ] Add teal border for scratchpad windows in looknfeel.conf
- [ ] Install hyprwhspr (`yay -S hyprwhspr && sudo pacman -S python-rich`)
- [ ] Configure hyprwhspr and enable systemd service
- [ ] Configure Ghostty with Mac-style keybindings
- [ ] Configure Zed with Mac-style keybindings
- [ ] Configure VS Code shift+enter binding
