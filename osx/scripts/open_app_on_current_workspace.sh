#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <AeroSpace app name> <command> [args...]" >&2
  exit 64
fi

app_name="$1"
shift

if ! command -v aerospace >/dev/null 2>&1; then
  exec "$@"
fi

target_workspace="$(aerospace list-workspaces --focused 2>/dev/null | head -n 1 || true)"

before_ids="$(mktemp)"
after_ids="$(mktemp)"
trap 'rm -f "$before_ids" "$after_ids"' EXIT

aerospace list-windows --all --format '%{window-id}|%{app-name}' 2>/dev/null |
  awk -F'|' -v app="$app_name" '$2 == app { print $1 }' >"$before_ids" || true

"$@" >/dev/null 2>&1 &

new_window_id=""
for _ in {1..40}; do
  sleep 0.10

  aerospace list-windows --all --format '%{window-id}|%{app-name}' 2>/dev/null |
    awk -F'|' -v app="$app_name" '$2 == app { print $1 }' >"$after_ids" || true

  new_window_id="$(comm -13 <(sort "$before_ids") <(sort "$after_ids") | tail -n 1 || true)"
  if [[ -n "$new_window_id" ]]; then
    break
  fi
done

# Some apps reuse an existing window or are slow to report the new one. Fall
# back to the focused window if it belongs to the launched app.
if [[ -z "$new_window_id" ]]; then
  focused_line="$(aerospace list-windows --focused --format '%{window-id}|%{app-name}' 2>/dev/null || true)"
  focused_app="${focused_line#*|}"
  if [[ "$focused_app" == "$app_name" ]]; then
    new_window_id="${focused_line%%|*}"
  fi
fi

if [[ -n "$new_window_id" && -n "$target_workspace" ]]; then
  aerospace move-node-to-workspace --window-id "$new_window_id" "$target_workspace" >/dev/null 2>&1 || true

  # Workspace 1 is tiled. Terminals/dev launchers should also tile wherever
  # they are opened so a terminal on a blank floating workspace fills it.
  case "$app_name" in
    Ghostty|WezTerm|Helium|Codex|Devin|"Code - Insiders"|"Visual Studio Code"|Zed|Cursor|Windsurf|Antigravity)
      aerospace layout --window-id "$new_window_id" tiling >/dev/null 2>&1 || true
      ;;
    *)
      if [[ "$target_workspace" == "1" ]]; then
        aerospace layout --window-id "$new_window_id" tiling >/dev/null 2>&1 || true
      else
        aerospace layout --window-id "$new_window_id" floating >/dev/null 2>&1 || true
      fi
      ;;
  esac

  aerospace workspace "$target_workspace" >/dev/null 2>&1 || true
fi
