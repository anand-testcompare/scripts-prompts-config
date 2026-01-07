#!/bin/bash

# Configuration Restore Script
# Restores configuration files from the backup directory

set -e

BACKUP_DIR="/home/anandpant/scripts-prompts-config/linux/config"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "Configuration Restore Script"
echo "============================"
echo "Restoring from: $BACKUP_DIR"
echo ""

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Backup directory not found at $BACKUP_DIR"
    exit 1
fi

# Create backup of existing configs before restore
echo "Creating backup of existing configurations..."
mkdir -p ~/config_backup_$TIMESTAMP

# Function to safely backup and restore
safe_restore() {
    local source="$1"
    local dest="$2"
    
    if [ -f "$source" ]; then
        # Backup existing file if it exists
        if [ -f "$dest" ]; then
            cp "$dest" ~/config_backup_$TIMESTAMP/$(basename "$dest")_backup
        fi
        # Restore from backup
        cp "$source" "$dest"
        echo "Restored: $dest"
    fi
}

safe_restore_dir() {
    local source="$1"
    local dest="$2"
    
    if [ -d "$source" ]; then
        # Backup existing directory if it exists
        if [ -d "$dest" ]; then
            cp -r "$dest" ~/config_backup_$TIMESTAMP/$(basename "$dest")_backup
        fi
        # Restore from backup
        mkdir -p "$(dirname "$dest")"
        cp -r "$source" "$dest"
        echo "Restored: $dest"
    fi
}

echo ""
echo "Restoring shell configurations..."
safe_restore "$BACKUP_DIR/.zshrc" ~/.zshrc
safe_restore "$BACKUP_DIR/.bashrc" ~/.bashrc
safe_restore "$BACKUP_DIR/.bashrc_dev" ~/.bashrc_dev
# Check for secrets template
if [ -f "$BACKUP_DIR/.shell_secrets.template" ] && [ ! -f ~/.shell_secrets ]; then
    echo "Creating .shell_secrets from template..."
    cp "$BACKUP_DIR/.shell_secrets.template" ~/.shell_secrets
    chmod 600 ~/.shell_secrets
    echo ""
    echo "IMPORTANT: Edit ~/.shell_secrets and add your actual API keys!"
    echo ""
fi

echo ""
echo "Restoring git configurations..."
safe_restore "$BACKUP_DIR/.gitconfig" ~/.gitconfig
safe_restore "$BACKUP_DIR/.gitignore_global" ~/.gitignore_global

echo ""
echo "Restoring application configurations..."
safe_restore_dir "$BACKUP_DIR/.config/kitty" ~/.config/kitty
safe_restore_dir "$BACKUP_DIR/.config/ohmyposh" ~/.config/ohmyposh

# Create claude directory if needed
mkdir -p ~/.claude
safe_restore "$BACKUP_DIR/.claude/CLAUDE.md" ~/.claude/CLAUDE.md
safe_restore "$BACKUP_DIR/.mcp.json" ~/.mcp.json
safe_restore "$BACKUP_DIR/.claude.json" ~/.claude.json

echo ""
echo "============================================"
echo "Restore complete!"
echo ""
echo "Existing configs were backed up to: ~/config_backup_$TIMESTAMP"
echo ""
echo "To apply the restored configurations:"
echo "  - For bash: source ~/.bashrc"
echo "  - For zsh:  source ~/.zshrc"
echo "  - Restart terminal applications for full effect"
echo ""
echo "If you need to rollback, your original configs are in:"
echo "  ~/config_backup_$TIMESTAMP"