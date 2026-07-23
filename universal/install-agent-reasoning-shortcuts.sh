#!/usr/bin/env bash
set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly CLAUDE_SOURCE="$REPO_ROOT/universal/.claude/keybindings.json"
readonly PI_SOURCE="$REPO_ROOT/universal/.pi/agent/extensions/thinking-level-shortcuts.ts"
readonly CLAUDE_TARGET="$HOME/.claude/keybindings.json"
readonly PI_TARGET="$HOME/.pi/agent/extensions/thinking-level-shortcuts.ts"

install_file() {
  local source="$1"
  local target="$2"
  local mode="$3"

  mkdir -p "$(dirname "$target")"
  if [[ -e "$target" ]] && ! cmp -s "$source" "$target"; then
    local backup="${target}.bak-$(date +%Y%m%d-%H%M%S)"
    cp -p "$target" "$backup"
    printf 'Backed up %s to %s\n' "$target" "$backup"
  fi
  install -m "$mode" "$source" "$target"
}

install_file "$CLAUDE_SOURCE" "$CLAUDE_TARGET" 600
install_file "$PI_SOURCE" "$PI_TARGET" 644

printf '%s\n' 'Installed Alt+. / Alt+, reasoning controls:'
printf '%s\n' '  Claude Code: increase/decrease effort in the model picker'
printf '%s\n' '  Pi: increase/decrease reasoning effort globally'
printf '%s\n' '  Codex: uses its native Alt+. / Alt+, bindings'
printf '%s\n' 'Run /reload in existing Pi sessions.'
