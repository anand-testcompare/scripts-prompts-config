#!/usr/bin/env bash

set -euo pipefail

show_help() {
  cat <<'EOF'
Usage: ./osx/scripts/configure_macos_defaults.sh [--disable-separate-spaces]

Applies macOS defaults that pair well with AeroSpace workspace workflows.

Options:
  --disable-separate-spaces  Also disable "Displays have separate Spaces"
                             (requires logout to fully take effect).
  -h, --help                 Show this help text.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  show_help
  exit 0
fi

if [[ $# -gt 1 ]]; then
  show_help >&2
  exit 1
fi

if [[ $# -eq 1 && "${1}" != "--disable-separate-spaces" ]]; then
  echo "Unknown argument: ${1}" >&2
  show_help >&2
  exit 1
fi

needs_logout="false"

apply_bool() {
  local domain="$1"
  local key="$2"
  local value="$3"
  local label="$4"
  local before after

  before="$(defaults read "$domain" "$key" 2>/dev/null || true)"
  if [[ -z "$before" ]]; then
    before="<unset>"
  fi

  defaults write "$domain" "$key" -bool "$value"
  after="$(defaults read "$domain" "$key")"

  printf '[ok] %s: %s -> %s\n' "$label" "$before" "$after"
}

echo "Applying macOS defaults for AeroSpace workflow..."

apply_bool \
  "com.apple.dock" \
  "workspaces-auto-swoosh" \
  "false" \
  "Do not switch to another Space for existing app windows"

apply_bool \
  "com.apple.dock" \
  "mru-spaces" \
  "false" \
  "Keep Spaces in a fixed order"

apply_bool \
  "com.apple.dock" \
  "expose-group-apps" \
  "true" \
  "Group windows by app in Mission Control"

if [[ "${1:-}" == "--disable-separate-spaces" ]]; then
  apply_bool \
    "com.apple.spaces" \
    "spans-displays" \
    "true" \
    "Disable 'Displays have separate Spaces'"
  needs_logout="true"
fi

killall Dock 2>/dev/null || true
killall cfprefsd 2>/dev/null || true

echo
echo "Done. Restarted Dock to apply changes."
if [[ "$needs_logout" == "true" ]]; then
  echo "Logout/login is required for 'Displays have separate Spaces' to fully apply."
fi
