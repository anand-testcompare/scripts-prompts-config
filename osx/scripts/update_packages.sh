#!/bin/bash

echo "🔄 Starting macOS package updates..."

echo "📦 Updating Homebrew and packages..."
brew update && brew upgrade

echo "🌍 Updating global npm packages..."
npm update -g

echo "🌍 Updating global pnpm packages..."
pnpm update -g

echo "🍎 Checking for macOS system updates..."
softwareupdate -l

echo "✅ Package updates complete!"
echo "💡 Run 'softwareupdate -ia' to install any available system updates"