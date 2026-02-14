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

Create `~/.skhdrc`:
```sh
cmd + shift - t [
  "Google Chrome" ~
  "Arc" ~
  "Safari" ~
  * : open -a Ghostty
]
cmd + shift - b : open -a "Google Chrome"
cmd + shift - f : open -a Finder
cmd + shift - a : open -a ChatGPT

# If you want true Omarchy, but it conflicts with send/submit in apps:
# cmd - return : open -a Ghostty
```

Start the service and grant Accessibility permissions to `skhd`:
```bash
skhd --start-service
```

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

## 6. Tmux (Omarchy-style on macOS)

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
- Ghostty truecolor compatibility (`xterm-ghostty:RGB`)
- TPM plugins: sensible, resurrect, continuum

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

---

## Summary Checklist

- [ ] Install terminal tools (Homebrew list above)
- [ ] Add macOS tool init + bindkeys to `~/.zshrc`
- [ ] Keep native `pbcopy/pbpaste/open`
- [ ] Add Omarchy-style aliases/functions to `~/.zshrc`
- [ ] Create `~/.config/starship.toml`
- [ ] Install and configure `skhd`, enable Accessibility, start service
- [ ] Copy Ghostty config and keybindings
- [ ] Copy tmux config and reload tmux
- [ ] Install AeroSpace + copy `~/.aerospace.toml` and enable Accessibility
