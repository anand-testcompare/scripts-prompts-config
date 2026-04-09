#!/usr/bin/env bash
set -euo pipefail

OMC_WRAPPER_CONFIG_DIR="${OMC_WRAPPER_CONFIG_DIR:-$HOME/.claude-omc}"
OMC_WRAPPER_STATE_DIR="${OMC_WRAPPER_STATE_DIR:-$OMC_WRAPPER_CONFIG_DIR/state}"

find_real_omc() {
  local self_path
  local npm_root
  local npm_prefix
  local candidate

  self_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

  if command -v npm >/dev/null 2>&1; then
    npm_root="$(npm root -g 2>/dev/null || true)"
    if [ -n "$npm_root" ]; then
      candidate="$npm_root/oh-my-claude-sisyphus/bridge/cli.cjs"
      if [ -x "$candidate" ] && [ "$candidate" != "$self_path" ]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    fi
  fi

  if command -v npm >/dev/null 2>&1; then
    npm_prefix="$(npm prefix -g 2>/dev/null || true)"
    if [ -n "$npm_prefix" ]; then
      candidate="$npm_prefix/bin/omc"
      if [ -x "$candidate" ] && [ "$candidate" != "$self_path" ]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    fi
  fi

  for candidate in /opt/homebrew/bin/omc /usr/local/bin/omc "$HOME/.npm-global/bin/omc"; do
    if [ -x "$candidate" ] && [ "$candidate" != "$self_path" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

if ! REAL_OMC_BIN="$(find_real_omc)"; then
  cat >&2 <<'EOF'
omc wrapper could not find the real OMC CLI.
Install it with:
  npm install -g oh-my-claude-sisyphus@latest
EOF
  exit 1
fi

export CLAUDE_CONFIG_DIR="$OMC_WRAPPER_CONFIG_DIR"
export OMC_STATE_DIR="$OMC_WRAPPER_STATE_DIR"

exec "$REAL_OMC_BIN" "$@"
