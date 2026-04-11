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
- `eza`-based `ls`, `lt`, `lta` that ignore inherited `NO_COLOR`
- `tree` with `-C` for colorized output
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
format = " [$branch]($style)"

[git_status]
style = "yellow"
format = " [$staged$modified$untracked$deleted$renamed$conflicted$stashed$ahead_behind]($style)"
staged = "+$count "
modified = "!$count "
untracked = "?$count "
deleted = "x$count "
renamed = ">$count "
conflicted = "=$count "
stashed = "*$count "
ahead = "^$count "
behind = "v$count "
diverged = "^$ahead_count v$behind_count "
up_to_date = ""

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

## 3b. Claude Code settings

Backed up Claude Code user settings live at:
- `osx/config/.claude/settings.json`

Copy them into place:
```bash
mkdir -p ~/.claude
cp osx/config/.claude/settings.json ~/.claude/settings.json
```

This tracked config does two important things:
- disables Claude Code commit and PR attribution globally with `"attribution": { "commit": "", "pr": "" }`
- points Claude's status line at the tracked repo script
- persists `/effort high` in `~/.claude/settings.json` as the fallback session default

```json
{
  "attribution": {
    "commit": "",
    "pr": ""
  },
  "statusLine": {
    "type": "command",
    "command": "bash /Users/anandpant/scripts-prompts-config/universal/claude-statusline.sh"
  },
  "effortLevel": "high"
}
```

If you want Claude Code to start at max effort on supported models, add this to `~/.zshrc`:

```bash
export CLAUDE_CODE_EFFORT_LEVEL=max
```

The script lives at:
- `universal/claude-statusline.sh`

It shows:
- model
- shortened working directory
- git branch plus compact dirty/ahead-behind counts
- tracked line additions/removals versus `HEAD`
- context usage
- Claude.ai 5-hour and 7-day usage when available

Notes:
- It caches git lookups for 5 seconds so the status line stays responsive in large repos.
- It uses two lines: repo identity/health on line 1, quantitative usage on line 2.
- Claude Code reads `statusLine`, `attribution`, and `effortLevel` from `~/.claude/settings.json`.
- Anthropic's current docs say `CLAUDE_CODE_EFFORT_LEVEL` takes precedence over both `/effort` and the persisted `effortLevel` setting.
- Anthropic's current docs say empty `attribution.commit` and `attribution.pr` strings hide both commit and PR attribution.

## 3c. OMC in an isolated profile

Use the tracked installer when you want `omc` available globally without letting OMC rewrite the normal `~/.claude` profile that `claude` uses:

```bash
bash universal/install-omc-isolated.sh
```

This does six things:
- installs the real OMC CLI package (`oh-my-claude-sisyphus`) globally
- relinks both the active global `omc` shim and `~/.local/bin/omc` to the tracked wrapper at `universal/omc-wrapper.sh`
- makes plain `omc` default to OMC's YOLO launch path while leaving management commands such as `omc setup` and `omc doctor` alone
- forces `omc` to run with `CLAUDE_CONFIG_DIR=~/.claude-omc` and `OMC_STATE_DIR=~/.claude-omc/state`
- on macOS, mirrors the existing Claude Code keychain login into the isolated OMC profile
- removes the legacy `gemini-image-generation` MCP registry entry from `~/.claude.json`, `~/.omc/mcp-registry.json`, and `~/.codex/config.toml`
- leaves `claude` on the normal `~/.claude` profile and configures global Git ignores from `osx/config/.config/git/ignore`

Result:
- `claude` keeps using your normal `~/.claude/settings.json` and `~/.claude/CLAUDE.md`
- `omc` uses the isolated `~/.claude-omc` tree instead
- repo-local OMC runtime files such as `.omc/`, `.claude/skills/omc-reference/`, and `.claude/CLAUDE-omc.md` stay globally ignored

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
  "Helium" ~
  * : open -a /Applications/Ghostty.app
]
cmd + shift - return : osascript -e 'tell application "Ghostty" to activate' -e 'tell application "Ghostty" to new window'
cmd + shift - b : open -na /Applications/Helium.app
cmd + shift - f : open -a Finder
cmd + shift - a : open -a ChatGPT

# If you want the old always-fresh Ghostty behavior:
# cmd - return : open -na /Applications/Ghostty.app
```

Start the service and grant Accessibility permissions to `skhd`:
```bash
skhd --start-service
launchctl kickstart -k gui/$(id -u)/com.koekeishiya.skhd
```

Notes:
- `Cmd+Shift+T` now reuses Ghostty by default, but passes through unchanged in Chrome, Arc, Safari, and Helium so those apps can keep their tab restore behavior.
- `Cmd+Shift+Return` now asks Ghostty to create a new window in the existing app via AppleScript, instead of relying on macOS app reopen behavior.
- This favors not accumulating stray Ghostty instances over keeping every launch pinned to the current macOS Space.
- If you explicitly want the old "always fresh instance" behavior back, switch the bindings to `open -na ...`.

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
- Cmd+Shift+Return new window (also mirrored globally in `skhd`)
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

Enable shell integration so splits inherit the shell's current working directory:
```bash
printf '\nif [[ "$TERM_PROGRAM" == "WezTerm" && -f /Applications/WezTerm.app/Contents/Resources/wezterm.sh ]]; then\n  source /Applications/WezTerm.app/Contents/Resources/wezterm.sh\nfi\n' >> ~/.zshrc
exec zsh
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
- Shell integration keeps WezTerm's tracked cwd in sync after `cd`, which is what makes `Cmd+D` and `Cmd+Shift+D` open in the directory you're actually working in.

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
- Mouse wheel scroll enters tmux scrollback/copy-mode inside full-screen TUIs (prevents Ghostty/tmux from turning wheel input into prompt-history navigation in Codex/Claude Code)
- `prefix + m` toggles tmux mouse mode off temporarily for native selection/Cmd-click links

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

One-command sync for the backed-up macOS window-manager and terminal configs:
```bash
./osx/scripts/apply_window_manager_setup.sh
```

Includes:
- `Cmd+Shift+Left/Right/Up/Down` move window to another monitor and follow
- `Cmd+Ctrl+F` maximize the focused window without using macOS native fullscreen
- `Alt+Shift+;`, then `r` force reset to tiled layout + flatten tree
- `Alt+Shift+;`, then `a` explicit accordion mode (only when intended)
- `Alt+Enter` reopen Ghostty without forcing a brand-new app instance
- A login-time retiling pass to clean up stacked/restored windows after reboot

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
- Remap screenshot full-screen from `Cmd+Shift+3` to `Ctrl+Cmd+3`
- Remap screenshot region from `Cmd+Shift+4` to `Ctrl+Cmd+4`
- Remap screenshot toolbar from `Cmd+Shift+5` to `Ctrl+Cmd+5`
- Leave `Cmd+Shift+3/4/5` free for tiling-manager bindings
- Brief finding: on this macOS 26 machine, `Ctrl+Shift+3/4/5` persisted in `com.apple.symbolichotkeys` but did not fire reliably at runtime, so the repo keeps the known-good `Ctrl+Cmd` mapping.

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
- [ ] Point `~/.claude/settings.json` at `universal/claude-statusline.sh`
- [ ] Install `skhd`, copy `~/.skhdrc`, enable Accessibility, restart service
- [ ] Copy Ghostty config and keybindings or WezTerm config
- [ ] Install AeroSpace + copy `~/.aerospace.toml` and enable Accessibility
- [ ] Run `osx/scripts/configure_macos_defaults.sh` (AeroSpace-friendly macOS defaults)
- [ ] Copy Zed keymap
- [ ] Run screenshot shortcut remap script for AeroSpace (`Cmd+Shift+3/4/5` conflicts)
