#!/bin/bash

# Configuration Backup Script
# Backs up essential configuration files to the scripts-prompts-config repository

set -e

BACKUP_DIR="/home/anandpant/scripts-prompts-config/linux/config"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "Configuration Backup Script"
echo "==========================="
echo "Backing up to: $BACKUP_DIR"
echo "Timestamp: $TIMESTAMP"
echo ""

# Create backup directory structure
mkdir -p "$BACKUP_DIR/.config/{kitty,ohmyposh}"
mkdir -p "$BACKUP_DIR/.claude"

# Shell configurations
echo "Backing up shell configurations..."
cp ~/.zshrc "$BACKUP_DIR/.zshrc"
cp ~/.bashrc "$BACKUP_DIR/.bashrc"
[ -f ~/.bashrc_dev ] && cp ~/.bashrc_dev "$BACKUP_DIR/.bashrc_dev"
# Don't backup secrets to repo - use template instead
echo "Skipping .shell_secrets (use .shell_secrets.template instead)"

# Git configurations
echo "Backing up git configurations..."
cp ~/.gitconfig "$BACKUP_DIR/.gitconfig"
cp ~/.gitignore_global "$BACKUP_DIR/.gitignore_global"

# Application configurations
echo "Backing up application configurations..."
[ -d ~/.config/kitty ] && cp -r ~/.config/kitty "$BACKUP_DIR/.config/"
[ -d ~/.config/ohmyposh ] && cp -r ~/.config/ohmyposh "$BACKUP_DIR/.config/"
[ -f ~/.claude/CLAUDE.md ] && cp ~/.claude/CLAUDE.md "$BACKUP_DIR/.claude/CLAUDE.md"
[ -f ~/.mcp.json ] && cp ~/.mcp.json "$BACKUP_DIR/.mcp.json"
[ -f ~/.claude.json ] && cp ~/.claude.json "$BACKUP_DIR/.claude.json"

# Create a manifest file
echo "Creating backup manifest..."
cat > "$BACKUP_DIR/BACKUP_MANIFEST.txt" << EOF
Configuration Backup Manifest
=============================
Date: $TIMESTAMP
Host: $(hostname)
User: $(whoami)

Files Backed Up:
----------------
EOF

# List all backed up files
find "$BACKUP_DIR" -type f -not -name "BACKUP_MANIFEST.txt" -not -name "*.sh" -not -name "*.md" | while read -r file; do
    echo "- ${file#$BACKUP_DIR/}" >> "$BACKUP_DIR/BACKUP_MANIFEST.txt"
done

echo ""
echo "Backup complete!"
echo "Manifest saved to: $BACKUP_DIR/BACKUP_MANIFEST.txt"
echo ""
echo "To restore these configurations on a new system:"
echo "1. Clone the scripts-prompts-config repository"
echo "2. Run: ./restore-configs.sh"