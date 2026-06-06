# scripts-prompts-config

A comprehensive configuration management system for development environments, supporting Linux and macOS. This repository contains backup/restore scripts, shell configurations, development tools setup, and AI prompts for maintaining consistent development environments.

## Current Platform Focus

- Primary: `osx/` and `linux-omarchy/`

## Quick Start

### macOS Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/scripts-prompts-config.git
cd scripts-prompts-config

# Apply backed-up macOS configs
cp osx/config/.aerospace.toml ~/.aerospace.toml
cp osx/config/.skhdrc ~/.skhdrc
mkdir -p ~/.claude
cp osx/config/.claude/settings.json ~/.claude/settings.json
mkdir -p ~/.config/ghostty
cp osx/config/.config/ghostty/config ~/.config/ghostty/config
mkdir -p ~/.config/wezterm
cp osx/config/.config/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua
mkdir -p ~/.config/zed
cp osx/config/zed/keymap.json ~/.config/zed/keymap.json

# Apply macOS defaults that fit AeroSpace workflows
./osx/scripts/configure_macos_defaults.sh

# Resolve macOS screenshot shortcut conflicts with AeroSpace Cmd+Shift+3/4
./osx/scripts/configure_screenshot_shortcuts.sh

# Or sync the window-manager stack in one step
./osx/scripts/apply_window_manager_setup.sh
```


## Features

### Development Environment

Both Bash and Zsh configurations include:

- **Version Managers**: NVM (Node.js), Bun runtime
- **Git Aliases**: `gs` (status), `ga` (add), `gc` (commit), `gp` (push), `gl` (log), `gd` (diff), `gco` (checkout), `gb` (branch)
- **Navigation**: Quick directory navigation (`..`, `...`, `....`)
- **Safety**: Interactive mode for destructive commands (`rm -i`, `cp -i`, `mv -i`)
- **Development Tools**: Local server (`serve`), IP info (`myip`), port checker (`ports`)
- **System Info**: Memory (`meminfo`), CPU (`cpuinfo`), disk usage (`diskinfo`)
- **Clipboard**: Cross-platform clipboard support (`pbcopy`, `pbpaste` via xclip)
- **Secure Credentials**: Automatic loading from `.shell_secrets`
- **Claude Code**: Tracked macOS user settings disable commit/PR attribution, point the Claude status line at `universal/claude-statusline.sh`, and persist `effortLevel: "high"`; `CLAUDE_CODE_EFFORT_LEVEL=max` in shell config overrides that to max on supported models
- **Exa MCP**: Tracked Codex/OpenCode configs use Exa's hosted MCP endpoint and enable `web_search_exa`, `web_search_advanced_exa`, `get_code_context_exa`, and `crawling_exa`. Keep any `EXA_API_KEY` usage local-only; do not commit it into repo-managed MCP URLs. The tracked OpenCode config now lives at `universal/.config/opencode/opencode.jsonc`
- **Codex Feature Banner**: `universal/codex-shell-tools.sh` wraps `codex` so interactive launches can compare current flags against a clean-home default baseline and highlight only the drifted values
- **pnpm 11 Defaults**: `osx/scripts/configure_pnpm_defaults.sh` activates `pnpm@11.5.1` through Corepack and writes persistent pnpm security defaults (`minimumReleaseAge`, exotic subdependency blocking, strict dependency builds) to pnpm's user config.
- **Modern CLI Tools**: eza (ls replacement), bat (cat replacement with automatic secret masking for `.env` files), ripgrep, fd
- **Pi/OMP Configuration**: Tracked templates for `~/.pi/agent/settings.json` and `~/.omp/agent/config.yml` with Fireworks AI provider support (models: `fireworks-openai/accounts/fireworks/routers/kimi-k2p5-turbo`, `fireworks-anthropic/accounts/fireworks/routers/kimi-k2p5-turbo`). Keep `FIREWORKS_API_KEY` local-only in `~/.shell_secrets`
- **OMP MCP Scope**: `osx/scripts/configure_omp_mcp_scope.sh` keeps user-level Windsurf MCP empty (`~/.codeium/windsurf/mcp_config.json`), creates the Larry generators MCP only at `~/Development/codestrap/.windsurf/mcp_config.json`, removes the Vercel Claude plugin cache, and clears stale OMP MCP cache entries. Keep `LARRY_API_KEY` local-only; export it before running the script if you want it embedded in the generated local Codestrap config.
- **Pi Extensions**: `universal/.pi/agent/extensions/` tracks portable global pi extensions, including `/exit` as an alias for `/quit` and `/merged` for post-merge verification follow-up

### Zsh-Specific Enhancements

- **Oh My Posh**: Git-aware prompt with custom themes
- **Syntax Highlighting**: Real-time command syntax validation
- **Auto-suggestions**: Intelligent command completion
- **FZF Integration**: Fuzzy file and history search

### Terminal Configuration (Kitty)

- Tokyo Night color scheme
- 85% background transparency
- JetBrains Mono Nerd Font
- Custom key bindings (Ctrl+C copy, Ctrl+V paste)
- Dynamic transparency controls (Ctrl+Shift+A + M/L)

## Repository Structure

```
scripts-prompts-config/
├── AGENTS.md                   # Shared repo workflow for coding agents
├── CLAUDE.md                   # AI assistant instructions
├── README.md                   # This file
├── TODO.md                     # Development tasks
├── linux-omarchy/             # Arch/Omarchy docs and scripts
│   ├── REPLICATION-GUIDE.md
│   ├── .shell_secrets.template
│   └── scripts/
│       └── emulate_osx_setups_arch_permanent.sh
├── osx/                       # macOS configurations/scripts
│   ├── README.md
│   └── scripts/
│       ├── configure_macos_defaults.sh
│       ├── configure_pnpm_defaults.sh
│       ├── configure_screenshot_shortcuts.sh
│       └── update_packages.sh
PX:└── universal/                 # Cross-platform scripts, hooks, and agent configs
TV:    ├── codex-shell-tools.sh
PB:    ├── convert_to_svg.sh
RT:    ├── kill-dev.sh
RT:    ├── optimize_logos.sh
PK:    ├── pi-google-code-assist-antigravity-troubleshooting.md
JK:    ├── .pi/agent/
QV:    │   ├── settings.json.template    # Pi agent configuration template
EX:    │   └── extensions/
AL:    │       ├── exit-command.ts       # Adds /exit alias for quitting pi
AL:    │       └── merged.ts             # Adds /merged post-merge follow-up prompt
RM:    ├── .omp/agent/
HQ:    │   └── config.yml.template         # OMP agent configuration template
RT:    └── git-hooks/
YQ:        ├── commit-msg
BN:        └── README.md
```

## Security

### Best Practices

1. **Never commit `.shell_secrets`, `.mcp.json`, `.claude.json`, or agent configs** - The repository `.gitignore` blocks these
2. **Use templates** - `.shell_secrets.template`, `.pi/agent/settings.json.template`, and `.omp/agent/config.yml.template` show the structure without real values
3. **Rotate exposed credentials** - Immediately rotate any accidentally exposed keys
4. **Proper permissions** - Scripts automatically set 600 on sensitive files

### Security Verification

All configuration files have been scanned and verified to contain:

- **NO API keys, tokens, or passwords** in committed files
- Only template files for sensitive configuration
- Proper gitignore rules to prevent accidental commits

## Installation Requirements

### Essential Tools

```bash
# macOS
brew install git curl zsh-autosuggestions zsh-history-substring-search fzf eza bat ripgrep fd zoxide atuin starship mise

# Omarchy/Arch
sudo pacman -Syu git curl wget zsh fzf eza bat ripgrep fd zoxide atuin starship

# Terminal
brew install --cask ghostty wezterm
# Omarchy/Arch terminal configs are tracked under linux-omarchy/configs/
```

### Development Tools

```bash
# Node Version Manager
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Bun
curl -fsSL https://bun.sh/install | bash

# Oh My Posh
curl -s https://ohmyposh.dev/install.sh | bash -s
```

### Fonts

```bash
# JetBrains Mono Nerd Font
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
unzip JetBrainsMono.zip -d ~/.fonts
fc-cache -fv
```

## Troubleshooting

### Commands not working after restore

```bash
source ~/.bashrc  # For bash
source ~/.zshrc   # For zsh
```

### NVM not found

```bash
# Reinstall NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
```

### Oh My Posh prompt not displaying

1. Ensure a Nerd Font is installed (see Fonts section)
2. Configure your terminal to use the Nerd Font
3. Restart your terminal

### Permission denied errors

```bash
# Fix script permissions
chmod +x osx/scripts/*.sh linux-omarchy/scripts/*.sh universal/*.sh
chmod 600 ~/.shell_secrets
```

## Utility Scripts

### Universal Scripts

#### kill-dev.sh

Interactive development process killer with 5 escalating levels:

```bash
./universal/kill-dev.sh
```

**Levels:**
1. **Dev servers only** - Kills processes on common dev ports (3000-3002, 5173, 8080, 4000, 8000)
2. **+ Node processes** - Adds Node, npm, yarn, pnpm and d3k/headless-Chrome cleanup
3. **+ Build tools** - Adds Vite, Next.js, Playwright, Jest, Vitest, Webpack
4. **+ IDEs** - Adds VSCode, WebStorm, IntelliJ IDEA, Cursor, Zed
5. **Nuclear option** - Everything including Docker, databases (Redis, PostgreSQL, MongoDB)

**Features:**
- Interactive menu-driven interface
- Graceful shutdown attempts before force kill (level 1)
- Confirmation required for nuclear option
- Color-coded output for clarity

### macOS Scripts

#### configure_macos_defaults.sh

Applies macOS defaults that improve AeroSpace workspace behavior:

```bash
./osx/scripts/configure_macos_defaults.sh
```

**Applies:**
- Disable app-triggered Space switching (`workspaces-auto-swoosh = false`)
- Keep Spaces in fixed order (`mru-spaces = false`)
- Group windows by app in Mission Control (`expose-group-apps = true`)

**Optional:**
- `./osx/scripts/configure_macos_defaults.sh --disable-separate-spaces`
  - Also disables `Displays have separate Spaces` (`spans-displays = true`)
  - Requires logout/login to fully apply

#### configure_pnpm_defaults.sh

Activates pnpm 11 through Corepack and writes pnpm's persistent user config:

```bash
./osx/scripts/configure_pnpm_defaults.sh
```

#### update_packages.sh

Updates package managers on macOS:

```bash
./osx/scripts/update_packages.sh
```

**Updates:**
- Homebrew and all installed packages
- pnpm 11/Corepack defaults
- Global pnpm packages
- Checks for macOS system updates

#### configure_screenshot_shortcuts.sh

Remaps screenshot shortcuts to `Ctrl+Cmd+3/4/5` so AeroSpace can own `Cmd+Shift+3/4`:

```bash
./osx/scripts/configure_screenshot_shortcuts.sh
```

**Applies:**
- Remap screenshot full screen to `Ctrl+Cmd+3`
- Remap screenshot region to `Ctrl+Cmd+4`
- Remap screenshot toolbar to `Ctrl+Cmd+5`

### Git Hooks

Install the commit-msg hook from `universal/git-hooks/` (see `universal/git-hooks/README.md`).

## Platform-Specific Documentation

- **Linux (Omarchy/Arch)**: See [linux-omarchy/REPLICATION-GUIDE.md](linux-omarchy/REPLICATION-GUIDE.md) for Omarchy setup details. Screenshot shortcuts are `Ctrl+Shift+3/4/5`.
- **macOS**: Utility scripts available in `osx/scripts/`
- **Universal tooling**: Pi + Google provider troubleshooting guide at [universal/pi-google-code-assist-antigravity-troubleshooting.md](universal/pi-google-code-assist-antigravity-troubleshooting.md)

## Contributing

When adding new configurations:

1. **Security check**: Scan for sensitive data before committing
2. **Test thoroughly**: Verify backup and restore scripts work
3. **Update documentation**: Keep READMEs current
4. **Maintain compatibility**: Ensure configs work across shells when possible

## License

MIT License - See [LICENSE](LICENSE) file for details
