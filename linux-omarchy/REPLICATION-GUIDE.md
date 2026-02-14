# Omarchy QoL Setup Replication Guide

This guide documents how to replicate the quality-of-life improvements made on top of base Omarchy.

---

## 0. Backup (Before Reinstall)

Create a backup snapshot of the Omarchy-related dotfiles/configs:

```bash
/home/anandpant/scripts-prompts-config/linux-omarchy/scripts/backup-omarchy-dotfiles.sh
```

This creates a timestamped folder under `backups/omarchy-dotfiles-*`.

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
Use the full, versioned file in this repo (so diffs are easy to review later):
```bash
cp /home/anandpant/scripts-prompts-config/linux-omarchy/configs/xremap-config.yml ~/.config/xremap/config.yml
```

Notes on the current layout:
- Global Super→Ctrl mappings (excluding Ghostty so Ghostty-only overrides always win).
- Ghostty-only overrides for Super+A/C/V/W/D so Ghostty uses Ctrl+Shift+… shortcuts and avoids clobbering terminal keys like Ctrl+D and Ctrl+T.
- Hyprland passthrough block for Super+Alt/Super+Ctrl combos.
- Super+Alt+D passthrough for dictation (`voxtype`).

### Autostart xremap (recommended: systemd --user)
```bash
mkdir -p ~/.config/systemd/user
cp /home/anandpant/scripts-prompts-config/linux-omarchy/configs/xremap.service ~/.config/systemd/user/xremap.service

systemctl --user daemon-reload
systemctl --user enable --now xremap.service
```

If you need device names, use: `xremap --list-devices`

Alternative (Hyprland autostart):
- Add to `~/.config/hypr/autostart.conf`:
```bash
exec-once = xremap --device "YOUR_KEYBOARD_NAME" ~/.config/xremap/config.yml
```

---

### Config Sync Checklist (Ghostty + xremap)
- Update live configs: `~/.config/ghostty/config` and `~/.config/xremap/config.yml`
- Restart xremap: `systemctl --user restart xremap`
- Reload Ghostty: Ctrl+Shift+, (or restart Ghostty)
- Copy into repo:
  - `cp ~/.config/ghostty/config ~/scripts-prompts-config/linux-omarchy/configs/ghostty-config`
  - `cp ~/.config/xremap/config.yml ~/scripts-prompts-config/linux-omarchy/configs/xremap-config.yml`
- Sanity check keys in Ghostty: Super+A/C/V/W/D and Ctrl+T

## 4. Hyprland Customizations

### Hyprland 0.53+ config compatibility (Omarchy defaults)

If you see `config option <misc:new_window_takes_over_fullscreen> does not exist` or `invalid field` errors, update the defaults to 0.53+ syntax:

```bash
# ~/.local/share/omarchy/default/hypr/looknfeel.conf
misc {
    on_focus_under_fullscreen = 1
}

# ~/.local/share/omarchy/default/hypr/windows.conf and apps/*.conf
# Replace legacy inline rules with windowrulev2
windowrulev2 = opacity 0.97 0.9, class:.*

# ~/.local/share/omarchy/default/hypr/apps/hyprshot.conf
layerrule = match:namespace selection, no_anim on

# ~/.local/share/omarchy/default/hypr/apps/walker.conf
layerrule = match:namespace walker, no_anim on

# ~/.config/hypr/input.conf (per-app scroll tweaks)
windowrule = match:class (Alacritty|kitty), scroll_touchpad 1.5
windowrule = match:class com.mitchellh.ghostty, scroll_touchpad 0.2
```

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

## 5. Voice Dictation (voxtype + GPU)

`voxtype` provides system-wide voice-to-text and is configured here to run on Vulkan (GPU).

### Install
```bash
yay -S voxtype-bin
```

### Configure

Quick apply from repo (recommended):
```bash
/home/anandpant/scripts-prompts-config/linux-omarchy/scripts/setup-voxtype-dictation.sh
```

Or copy manually:

Copy the versioned files from this repo:
```bash
mkdir -p ~/.config/voxtype ~/.config/systemd/user/voxtype.service.d ~/.local/bin
cp /home/anandpant/scripts-prompts-config/linux-omarchy/configs/voxtype-config.toml ~/.config/voxtype/config.toml
cp /home/anandpant/scripts-prompts-config/linux-omarchy/configs/voxtype.service ~/.config/systemd/user/voxtype.service
cp /home/anandpant/scripts-prompts-config/linux-omarchy/configs/voxtype-backend.conf ~/.config/systemd/user/voxtype.service.d/backend.conf
cp /home/anandpant/scripts-prompts-config/linux-omarchy/configs/voxtype-gpu.conf ~/.config/systemd/user/voxtype.service.d/gpu.conf
cp /home/anandpant/scripts-prompts-config/linux-omarchy/configs/hyprwhspr-compat ~/.local/bin/hyprwhspr
chmod +x ~/.local/bin/hyprwhspr
```

Notes:
- `backend.conf` forces the Vulkan binary (`/usr/lib/voxtype/voxtype-vulkan daemon`).
- `gpu.conf` pins GPU selection to NVIDIA (`VOXTYPE_VULKAN_DEVICE=nvidia`).
- `hyprwhspr-compat` keeps old `hyprwhspr` command muscle memory working by forwarding to `voxtype`.

### Enable systemd service (persists across restart/login)
```bash
systemctl --user daemon-reload
systemctl --user enable --now voxtype.service
systemctl --user is-enabled voxtype.service
```

### Hyprland binding
Add to `~/.config/hypr/bindings.conf`:
```
bindd = SUPER ALT, D, Dictation, exec, voxtype record toggle
```

If you use xremap, keep passthroughs so Super+Alt+D reaches Hyprland:
```
Super_L-Alt_L-d: Super_L-Alt_L-d
Super_L-Alt_R-d: Super_L-Alt_R-d
Super_R-Alt_L-d: Super_R-Alt_L-d
Super_R-Alt_R-d: Super_R-Alt_R-d
```

### Usage
- `Super+Alt+D` - Toggle recording (press once to start, again to stop and transcribe)
- `hyprwhspr toggle` - Compatibility alias for old workflow

---

## 7. Ghostty Terminal Config

Copy the full config so it stays in sync with the repo:
```bash
cp /home/anandpant/scripts-prompts-config/linux-omarchy/configs/ghostty-config ~/.config/ghostty/config
```

Notes:
- Uses the Omarchy theme file via `config-file = ?"~/.config/omarchy/current/theme/ghostty.conf"`.
- Super-based bindings remain in Ghostty, but Ghostty-specific xremap overrides map Super+A/C/V/W/D to Ctrl+Shift+… in Ghostty.
- Ctrl+Shift+W is bound to `close_surface` so Super+W closes the current split (not the entire window).

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
- [ ] Install voxtype (`yay -S voxtype-bin`)
- [ ] Copy voxtype config/service/drop-ins and enable `voxtype.service`
- [ ] Configure Ghostty with Mac-style keybindings
- [ ] Configure Zed with Mac-style keybindings
- [ ] Configure VS Code shift+enter binding
