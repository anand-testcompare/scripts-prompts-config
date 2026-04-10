#!/usr/bin/env bash
set -euo pipefail

OMC_WRAPPER_CONFIG_DIR="${OMC_WRAPPER_CONFIG_DIR:-$HOME/.claude-omc}"
OMC_WRAPPER_STATE_DIR="${OMC_WRAPPER_STATE_DIR:-$OMC_WRAPPER_CONFIG_DIR/state}"
OMC_WRAPPER_DEFAULT_YOLO="${OMC_WRAPPER_DEFAULT_YOLO:-1}"

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

is_falsey() {
  local normalized
  normalized="$(printf '%s' "${1-}" | tr '[:upper:]' '[:lower:]')"

  case "$normalized" in
    0|false|no|off)
      return 0
      ;;
  esac

  return 1
}

should_force_default_yolo() {
  if is_falsey "$OMC_WRAPPER_DEFAULT_YOLO"; then
    return 1
  fi

  case "${1-}" in
    ""|launch)
      ;;
    -h|--help|-V|--version|version|help|setup|doctor|install|update|update-reconcile|config|config-stop-callback|config-notify-profile|info|test-prompt|interop|ask|wait|teleport|session|sessions|list|remove|search|status|daemon|detect|postinstall|hud|mission-board|team|autoresearch|ralphthon)
      return 1
      ;;
  esac

  local start_index=0
  if [ "${1-}" = "launch" ]; then
    start_index=1
  fi

  local -a args
  args=("$@")
  local arg
  local index
  for ((index = start_index; index < ${#args[@]}; index += 1)); do
    arg="${args[index]}"
    case "$arg" in
      -h|--help|-V|--version|--yolo|--madmax|--dangerously-skip-permissions|--permission-mode|--approval-mode)
        return 1
        ;;
      --dangerously-skip-permissions=*|--permission-mode=*|--approval-mode=*)
        return 1
        ;;
    esac
  done

  return 0
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

if should_force_default_yolo "$@"; then
  set -- "$@" --yolo
fi

exec "$REAL_OMC_BIN" "$@"
