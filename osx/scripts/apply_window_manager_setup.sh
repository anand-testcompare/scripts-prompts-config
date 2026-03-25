#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

install -m 0644 "$repo_root/osx/config/.aerospace.toml" "$HOME/.aerospace.toml"
install -m 0644 "$repo_root/osx/config/.skhdrc" "$HOME/.skhdrc"
mkdir -p "$HOME/.config/ghostty"
install -m 0644 "$repo_root/osx/config/.config/ghostty/config" "$HOME/.config/ghostty/config"

"$repo_root/osx/scripts/configure_macos_defaults.sh"

if pgrep -x AeroSpace >/dev/null 2>&1; then
  aerospace reload-config
else
  open -a AeroSpace
fi

if command -v skhd >/dev/null 2>&1; then
  skhd --start-service >/dev/null 2>&1 || true
  launchctl kickstart -k "gui/$(id -u)/com.koekeishiya.skhd" >/dev/null 2>&1 || true
fi

echo "Window manager configs synced from $repo_root"
