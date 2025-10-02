# scripts-prompts-config

A comprehensive configuration management system for development environments, supporting both Linux and macOS. This repository contains backup/restore scripts, shell configurations, development tools setup, and AI prompts for maintaining consistent development environments.

## Quick Start

### Linux Setup on New System

```bash
# Clone the repository
git clone https://github.com/yourusername/scripts-prompts-config.git
cd scripts-prompts-config/linux

# Restore all configurations
./restore-configs.sh

# Configure your API keys
cp ~/.shell_secrets.template ~/.shell_secrets
nano ~/.shell_secrets  # Add your actual API keys
chmod 600 ~/.shell_secrets

# Apply configurations
source ~/.bashrc  # For bash
source ~/.zshrc   # For zsh
```

### Backup Current Configurations

```bash
cd scripts-prompts-config/linux
./backup-configs.sh
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

### Zsh-Specific Enhancements

- **Oh My Posh**: Git-aware prompt with custom themes
- **Syntax Highlighting**: Real-time command syntax validation
- **Auto-suggestions**: Intelligent command completion
- **FZF Integration**: Fuzzy file and history search
- **Modern CLI Tools**: exa (ls replacement), bat (cat replacement), ripgrep, fd

### Terminal Configuration (Kitty)

- Tokyo Night color scheme
- 85% background transparency
- JetBrains Mono Nerd Font
- Custom key bindings (Ctrl+C copy, Ctrl+V paste)
- Dynamic transparency controls (Ctrl+Shift+A + M/L)

## Repository Structure

```
scripts-prompts-config/
├── CLAUDE.md                   # AI assistant instructions
├── README.md                   # This file
├── TODO.md                     # Development tasks
├── linux/
│   ├── backup-configs.sh      # Backup script
│   ├── restore-configs.sh     # Restore script
│   ├── config/                # Configuration files
│   │   ├── README.md          # Linux-specific documentation
│   │   ├── .bashrc            # Bash configuration
│   │   ├── .zshrc             # Zsh configuration
│   │   ├── .gitconfig         # Git settings
│   │   ├── .gitignore_global  # Global gitignore
│   │   ├── .claude/           # Claude AI settings
│   │   ├── .config/           # Application configs
│   │   └── ...
│   ├── prompts/               # AI maintenance prompts
│   │   └── sync-shell-configs.md
│   └── scripts/               # Utility scripts
│       └── emulate_osx_setups.sh
└── osx/                       # macOS configurations
    ├── config/
    ├── prompts/
    └── scripts/               # macOS utility scripts
        ├── kill-dev.sh        # Interactive dev process killer
        └── update_packages.sh # System package updater
```

## Security

### Best Practices

1. **Never commit `.shell_secrets`** - The `.gitignore` prevents this
2. **Use the template** - `.shell_secrets.template` shows the structure without real values
3. **Rotate exposed credentials** - Immediately rotate any accidentally exposed keys
4. **Proper permissions** - Scripts automatically set 600 on sensitive files

### Security Verification

All configuration files have been scanned and verified to contain:

- **NO API keys, tokens, or passwords** in committed files
- Only template files for sensitive configuration
- Proper gitignore rules to prevent accidental commits

## Shell Synchronization

Keep bash and zsh configurations synchronized using the included prompt:

```bash
# Use the sync prompt with your AI assistant
cat linux/prompts/sync-shell-configs.md
```

This ensures consistent:

- Development tools and version managers
- PATH modifications
- Environment variables
- Aliases and functions
- Third-party tool integrations

## Installation Requirements

### Essential Tools

```bash
# Package manager updates
sudo apt update && sudo apt upgrade  # Debian/Ubuntu
sudo dnf update                      # Fedora

# Core utilities
sudo apt install git curl wget xclip

# Zsh and enhancements
sudo apt install zsh zsh-syntax-highlighting zsh-autosuggestions

# Modern CLI tools
sudo apt install exa bat ripgrep fd-find fzf

# Terminal
sudo apt install kitty
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
chmod +x linux/*.sh
chmod 600 ~/.shell_secrets
```

## Utility Scripts

### macOS Scripts

#### kill-dev.sh

Interactive development process killer with 5 escalating levels:

```bash
./osx/scripts/kill-dev.sh
```

**Levels:**
1. **Dev servers only** - Kills processes on common dev ports (3000-3002, 5173, 8080, 4000, 8000)
2. **+ Node processes** - Adds Node, npm, yarn, pnpm processes
3. **+ Build tools** - Adds Vite, Next.js, Playwright, Jest, Vitest, Webpack
4. **+ IDEs** - Adds VSCode, WebStorm, IntelliJ IDEA, Cursor, Zed
5. **Nuclear option** - Everything including Docker, databases (Redis, PostgreSQL, MongoDB)

**Features:**
- Interactive menu-driven interface
- Graceful shutdown attempts before force kill (level 1)
- Confirmation required for nuclear option
- Color-coded output for clarity

#### update_packages.sh

Updates all package managers on macOS:

```bash
./osx/scripts/update_packages.sh
```

**Updates:**
- Homebrew and all installed packages
- Global npm packages
- Global pnpm packages
- Checks for macOS system updates

## Platform-Specific Documentation

- **Linux**: See [linux/config/README.md](linux/config/README.md) for detailed Linux configuration information
- **macOS**: Utility scripts available in `osx/scripts/`

## Contributing

When adding new configurations:

1. **Security check**: Scan for sensitive data before committing
2. **Test thoroughly**: Verify backup and restore scripts work
3. **Update documentation**: Keep READMEs current
4. **Maintain compatibility**: Ensure configs work across shells when possible

## License

MIT License - See [LICENSE](LICENSE) file for details
