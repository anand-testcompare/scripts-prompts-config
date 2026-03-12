# macOS QoL Setup (Local)

This file documents the macOS changes applied in this session.

---

## 1. Terminal QoL Tools (Homebrew)

Install:
```bash
brew install zsh-autosuggestions zsh-history-substring-search fzf eza bat zoxide atuin starship mise
```

Add to `~/.zshrc`:
```bash
# Syntax highlighting
source /opt/homebrew/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh

# fzf integration (Ctrl+R for history, Ctrl+T for files, Alt+C for cd)
source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
source /opt/homebrew/opt/fzf/shell/completion.zsh

# history-substring-search on arrow keys / Ctrl+P/N
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down

eval "$(zoxide init zsh --cmd cd)"
eval "$(atuin init zsh)"
eval "$(starship init zsh)"
eval "$(mise activate zsh)"
```

Notes:
- Keep native `pbcopy`, `pbpaste`, and `open` on macOS (do not override).

---

## 2. Aliases and helpers

The following Omarchy-style aliases/functions were added to `~/.zshrc`:
- `eza`-based `ls`, `lt`, `lta`
- `bat` for `cat` (with secret masking for env-like files)
- `ff` (fzf preview), `..`/`...`/`....` navigation
- git aliases (`g`, `gcm`, `gcam`, `gcad`)
- `n()` helper for `nvim`
- archive helpers and media helpers (ffmpeg/imagemagick)

---

## 3. Starship (clean prompt)

Create `~/.config/starship.toml` to remove cloud context and keep a clean prompt.
You can copy the repo version from `osx/starship.toml`:
```toml
format = "$directory$git_branch$git_status$nodejs$python$golang$rust$line_break$character"
add_newline = true

[directory]
style = "bold cyan"
truncation_length = 3
truncation_symbol = "../"
read_only = " ro"

[git_branch]
symbol = ""
style = "bold purple"
format = " on [$branch]($style)"

[git_status]
style = "yellow"
format = " [$all_status$ahead_behind]($style)"
# Keep this a simple, valid format string to avoid parse errors.
stashed = " stash:$count"

[nodejs]
symbol = ""
style = "green"
format = " via [$version]($style)"

[python]
symbol = ""
style = "blue"
format = " via [$version]($style)"

[golang]
symbol = ""
style = "blue"
format = " via [$version]($style)"

[rust]
symbol = ""
style = "red"
format = " via [$version]($style)"

[character]
success_symbol = "> "
error_symbol = "> "

[aws]
disabled = true

[gcloud]
disabled = true

[kubernetes]
disabled = true
```

---

## 4. Omarchy-style app launch keys (skhd)

Install:
```bash
brew tap koekeishiya/formulae
brew install skhd
```

Backed up `skhd` config lives at:
- `osx/config/.skhdrc`

Copy to your local machine:
```bash
cp osx/config/.skhdrc ~/.skhdrc
```

Config includes:
```sh
cmd + shift - t [
  "Google Chrome" ~
  "Arc" ~
  "Safari" ~
  * : open -na /Applications/Ghostty.app
]
cmd + shift - b : open -na /Applications/Helium.app
cmd + shift - f : open -a Finder
cmd + shift - a : open -a ChatGPT

# If you want true Omarchy, but it conflicts with send/submit in apps:
# cmd - return : open -na /Applications/Ghostty.app
```

Start the service and grant Accessibility permissions to `skhd`:
```bash
skhd --start-service
launchctl kickstart -k gui/$(id -u)/com.koekeishiya.skhd
```

Notes:
- The launcher uses `open -na` on purpose so new windows open in your current workspace instead of jumping to an existing app window in another macOS Space.
- Expected tradeoff: each fresh app instance shows as its own icon in the Dock while running.
- If you prefer single Dock app grouping, switch those bindings back to `open -a ...`, but macOS may jump to another Space.

---

## 5. Ghostty keybindings

Backed up Ghostty config lives at:
- `osx/config/.config/ghostty/config`

Copy to your local machine:
```bash
mkdir -p ~/.config/ghostty
cp osx/config/.config/ghostty/config ~/.config/ghostty/config
```

Keybindings included:
- Cmd+D split right
- Cmd+Shift+D split down
- Cmd+T new tab
- Cmd+N new window
- Cmd+W close pane
- Cmd+{/} previous/next tab

---

## 5b. WezTerm (native-first default)

Backed up WezTerm config lives at:
- `osx/config/.config/wezterm/wezterm.lua`

Install:
```bash
brew install --cask wezterm
```

Copy to your local machine:
```bash
mkdir -p ~/.config/wezterm
cp osx/config/.config/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua
```

Behavior:
- Connects the GUI to a local WezTerm mux domain named `main`
- Native panes/tabs/workspaces, no tmux required
- Cmd+D split right
- Cmd+Shift+D split down
- Cmd+T new tab
- Cmd+W close current pane
- Cmd+Shift+{/} previous/next tab
- Cmd+Shift+L launcher for tabs/workspaces
- Cmd+Shift+P pane picker
- Cmd+N new macOS WezTerm window (attached to the same local mux domain)
- Cmd+= / Cmd+- / Cmd+0 font zoom controls

Notes:
- Using a local mux domain gives you durable local tabs/workspaces without layering tmux inside WezTerm.

---

## 6. Tmux (optional legacy path)

Backed up tmux config lives at:
- `osx/config/.tmux.conf`

Copy to your local machine:
```bash
cp osx/config/.tmux.conf ~/.tmux.conf
tmux source-file ~/.tmux.conf
```

Includes:
- `Ctrl+Space` prefix (`C-b` unbound)
- Omarchy-style statusline and pane colors
- Vim pane movement/resizing + mouse support
- Truecolor compatibility for Ghostty and WezTerm (`xterm-ghostty:RGB`, `wezterm:RGB`)
- TPM plugins: sensible, resurrect, continuum

Use this only if you explicitly want tmux for remote persistence or a terminal-agnostic workflow. The main macOS path in this repo is now WezTerm-native.

---

## 7. AeroSpace (tiling + workspaces)

AeroSpace is an i3-like tiling window manager for macOS.

Install:
```bash
brew install --cask nikitabobko/tap/aerospace
```

Copy the Omarchy-style config (Cmd+1..9 focus workspace, Cmd+Shift+1..9 move window and follow):
```bash
cp osx/config/.aerospace.toml ~/.aerospace.toml
```

Then launch `AeroSpace.app` and grant it Accessibility permissions:
- System Settings -> Privacy & Security -> Accessibility -> enable `AeroSpace`

Reload config after edits:
```bash
aerospace reload-config
```

Includes:
- `Cmd+Shift+Left/Right/Up/Down` move window to another monitor and follow
- `Alt+Shift+;`, then `r` force reset to tiled layout + flatten tree
- `Alt+Shift+;`, then `a` explicit accordion mode (only when intended)
- `Alt+Enter` open a fresh Ghostty app instance (`open -na`) for new workspace sessions

Recommended macOS defaults for AeroSpace workflows:
```bash
./osx/scripts/configure_macos_defaults.sh
```

This sets:
- Disable "When switching to an application, switch to a Space with open windows"
- Keep Spaces in fixed order (disable automatic rearranging)
- Enable "Group windows by application" in Mission Control

Important:
- By default macOS uses `Cmd+Shift+3/4/5` for screenshots.
- This conflicts with AeroSpace `Cmd+Shift+3/4` workspace move bindings.
- Run `osx/scripts/configure_screenshot_shortcuts.sh` (below) to resolve this.

---

## 8. Zed keybindings (global dock toggles)

Backed up keymap lives at:
- `osx/config/zed/keymap.json`

Copy to your local machine:
```bash
mkdir -p ~/.config/zed
cp osx/config/zed/keymap.json ~/.config/zed/keymap.json
```

Keybindings included:
- `Ctrl+B` toggle left dock
- `Ctrl+I` toggle right dock

---

## 9. macOS defaults script (for AeroSpace)

Apply macOS defaults that work better with AeroSpace workspace behavior:

```bash
chmod +x osx/scripts/configure_macos_defaults.sh
./osx/scripts/configure_macos_defaults.sh
```

Optional (multi-monitor): disable `Displays have separate Spaces` as well:

```bash
./osx/scripts/configure_macos_defaults.sh --disable-separate-spaces
```

Notes:
- The script restarts Dock automatically.
- If you pass `--disable-separate-spaces`, logout/login is required.

---

## 10. Screenshot shortcut conflict fix (for AeroSpace)

This script configures macOS screenshot shortcuts to avoid conflict with AeroSpace:
- Remap screenshot full-screen from `Cmd+Shift+3` to `Cmd+Ctrl+3`
- Remap screenshot region from `Cmd+Shift+4` to `Cmd+Ctrl+4`
- Remap screenshot toolbar from `Cmd+Shift+5` to `Cmd+Ctrl+5`
- Leave `Cmd+Shift+3/4/5` free for tiling-manager bindings

Run:
```bash
chmod +x osx/scripts/configure_screenshot_shortcuts.sh
./osx/scripts/configure_screenshot_shortcuts.sh
```

The script creates a backup at:
- `~/Library/Preferences/com.apple.symbolichotkeys.plist.bak-YYYYMMDD-HHMMSS`
- `osx/config/screenshot-shortcuts-cmd-ctrl-345.json` (tracked snapshot of the intended mapping)

---

## Summary Checklist

- [ ] Install terminal tools (Homebrew list above)
- [ ] Add macOS tool init + bindkeys to `~/.zshrc`
- [ ] Keep native `pbcopy/pbpaste/open`
- [ ] Add Omarchy-style aliases/functions to `~/.zshrc`
- [ ] Create `~/.config/starship.toml`
- [ ] Install `skhd`, copy `~/.skhdrc`, enable Accessibility, restart service
- [ ] Copy Ghostty config and keybindings or WezTerm config
- [ ] Install AeroSpace + copy `~/.aerospace.toml` and enable Accessibility
- [ ] Run `osx/scripts/configure_macos_defaults.sh` (AeroSpace-friendly macOS defaults)
- [ ] Copy Zed keymap
- [ ] Run screenshot shortcut remap script for AeroSpace (`Cmd+Shift+3/4/5` conflicts)
