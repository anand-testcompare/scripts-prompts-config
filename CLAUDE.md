# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository (`scripts-prompts-config`) is a configuration management system for development environments, supporting both Linux and macOS. It contains backup/restore scripts for shell configurations, development tools, and application settings.

## Key Scripts and Commands

### Configuration Management

- **Backup configurations**: `./linux/backup-configs.sh` - Backs up current system configurations to the repository
- **Restore configurations**: `./linux/restore-configs.sh` - Restores configurations from repository to system
- **Test restore**: Always create backups before restoring (script does this automatically)

### Directory Structure

```bash
scripts-prompts-config/
├── linux/
│   ├── backup-configs.sh      # Main backup script
│   ├── restore-configs.sh     # Main restore script
│   ├── config/                # Backed up configuration files
│   │   ├── .bashrc
│   │   ├── .zshrc
│   │   ├── .gitconfig
│   │   ├── .config/
│   │   └── .claude/
│   ├── prompts/               # AI prompts for maintenance
│   └── scripts/               # Utility scripts
└── osx/                       # macOS configurations (to be populated)
```

## Architecture and Design

### Backup/Restore System

- Scripts use `safe_restore()` functions to prevent accidental data loss
- Automatic timestamped backups of existing configs before restore
- Manifest file generation for tracking backed-up files
- Excludes sensitive files (`.shell_secrets`) from repository

### Security Considerations

- Never commit `.shell_secrets` - use `.shell_secrets.template` instead
- Scripts set proper permissions (600) on sensitive files
- All configuration files have been scanned for sensitive data

### Shell Configuration Sync

The repository maintains synchronized configurations between bash and zsh for:

- Development tools (NVM, Bun, language version managers)
- PATH modifications and environment variables
- Aliases and utility functions
- Third-party tool integrations (FZF, Docker, cloud CLIs)

## Important Notes

1. **Security**: Never include actual API keys, tokens, or passwords in any files committed to this repository
2. **Testing**: After restoring configurations, source the shell files (`source ~/.bashrc` or `source ~/.zshrc`)
3. **Compatibility**: Scripts are designed for Linux environments, macOS support is planned but not yet implemented
4. **Backup First**: The restore script automatically creates backups, but manual backups are recommended for critical systems
