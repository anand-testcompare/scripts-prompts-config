#!/usr/bin/env bash
set -euo pipefail

# Configure macOS LaunchServices default apps for common file types.
# Preference split:
# - Zed for code/config/docs/text
# - Sublime Text for logs, because it is very fast with huge log files
# - Leave browser/images/PDF/CSV defaults alone

ZED_BUNDLE_ID="${ZED_BUNDLE_ID:-dev.zed.Zed}"
SUBLIME_BUNDLE_ID="${SUBLIME_BUNDLE_ID:-com.sublimetext.4}"

if ! command -v duti >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo "Installing duti with Homebrew..."
    brew install duti
  else
    echo "Error: duti is required and Homebrew was not found." >&2
    echo "Install Homebrew or install duti manually, then rerun this script." >&2
    exit 1
  fi
fi

set_default() {
  local bundle_id="$1"
  local uti="$2"
  local label="${3:-$uti}"
  echo "Setting ${label} -> ${bundle_id}"
  duti -s "$bundle_id" "$uti" all
}

# Zed for Markdown, text, structured config, and source files.
set_default "$ZED_BUNDLE_ID" net.daringfireball.markdown "Markdown (.md/.markdown)"
set_default "$ZED_BUNDLE_ID" public.plain-text "plain text (.txt and many text files)"
set_default "$ZED_BUNDLE_ID" public.json "JSON"
set_default "$ZED_BUNDLE_ID" public.yaml "YAML"
set_default "$ZED_BUNDLE_ID" public.xml "XML"
set_default "$ZED_BUNDLE_ID" public.css "CSS"
set_default "$ZED_BUNDLE_ID" com.netscape.javascript-source "JavaScript"
set_default "$ZED_BUNDLE_ID" com.microsoft.typescript "TypeScript/TSX"
set_default "$ZED_BUNDLE_ID" public.python-script "Python"
set_default "$ZED_BUNDLE_ID" public.ruby-script "Ruby"
set_default "$ZED_BUNDLE_ID" com.sun.java-source "Java"
set_default "$ZED_BUNDLE_ID" public.c-source "C"
set_default "$ZED_BUNDLE_ID" public.c-plus-plus-source "C++"
set_default "$ZED_BUNDLE_ID" public.c-header "C header"
set_default "$ZED_BUNDLE_ID" public.c-plus-plus-header "C++ header"
set_default "$ZED_BUNDLE_ID" public.shell-script "shell script"
set_default "$ZED_BUNDLE_ID" public.zsh-script "Zsh script"

# Dynamic UTIs observed on macOS for extension-only/dev files.
# These can be machine-created by LaunchServices when no exported UTI exists.
set_default "$ZED_BUNDLE_ID" dyn.ah62d4rv4ge8043d2 "MDX (.mdx)"
set_default "$ZED_BUNDLE_ID" dyn.ah62d4rv4ge80y65tr3vu "JSONC (.jsonc)"
set_default "$ZED_BUNDLE_ID" dyn.ah62d4rv4ge81k55rru "TOML (.toml)"
set_default "$ZED_BUNDLE_ID" dyn.ah62d4rv4ge81g25xsq "SCSS (.scss)"
set_default "$ZED_BUNDLE_ID" dyn.ah62d4rv4ge80y652 "JSX (.jsx)"
set_default "$ZED_BUNDLE_ID" dyn.ah62d4rv4ge80s52 "Go (.go)"
set_default "$ZED_BUNDLE_ID" dyn.ah62d4rv4ge81e62 "Rust (.rs)"
set_default "$ZED_BUNDLE_ID" dyn.ah62d4rv4ge81g6pq "SQL (.sql)"
set_default "$ZED_BUNDLE_ID" dyn.ah62d4rv4ge80s4pyrfx0655wqy "gitignore (.gitignore)"
set_default "$ZED_BUNDLE_ID" dyn.ah62d4rv4ge80k55drrw1e3xmrvwu "Dockerfile"
set_default "$ZED_BUNDLE_ID" dyn.ah62d4rv4ge80255drq "lock files (.lock)"

# Sublime for logs.
set_default "$SUBLIME_BUNDLE_ID" com.apple.log "logs (.log)"

# Intentionally not setting public.mpeg-2-transport-stream for .ts, because macOS
# often maps .ts to MPEG transport stream video rather than TypeScript.

killall Finder >/dev/null 2>&1 || true

echo "Done. Finder restarted. If an app still appears stale, log out/in or rebuild LaunchServices."
