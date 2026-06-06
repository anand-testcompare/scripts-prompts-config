#!/bin/bash
set -euo pipefail

echo "🔄 Starting macOS package updates..."

echo "📦 Updating Homebrew and packages..."
brew update && brew upgrade

echo "📦 Ensuring pnpm 11 defaults..."
bash "$(dirname "$0")/configure_pnpm_defaults.sh"

echo "🌍 Updating global pnpm packages..."
pnpm update -g

echo "🍎 Checking for macOS system updates..."
softwareupdate -l

echo "✅ Package updates complete!"
echo "💡 Run 'softwareupdate -ia' to install any available system updates"
