#!/usr/bin/env bash

set -euo pipefail

if ! command -v aerospace >/dev/null 2>&1; then
  exit 0
fi

# Give macOS a moment to restore login items before forcing workspaces back
# into the workspace policy. This reduces the "stacked on top of each other
# after reboot" failure mode when apps re-open before AeroSpace finishes
# settling.
sleep "${AEROSPACE_STARTUP_DELAY:-4}"

focused_workspace="$(aerospace list-workspaces --focused 2>/dev/null | head -n 1 || true)"

# Workspace policy:
# - Workspace 1 is the dedicated tiling workspace.
# - Workspaces 2+ are floating workspaces.
# - Utility/overlay apps should not consume tile space on workspace 1.
utility_app_regex='^(Helium|ChatGPT|Wispr Flow)$'

# First, move utility/overlay apps off workspace 1 so they do not reserve
# invisible/awkward tile space there.
aerospace list-windows --workspace 1 --format '%{window-id}|%{app-name}' 2>/dev/null |
  while IFS='|' read -r window_id app_name; do
    [[ -n "$window_id" ]] || continue

    if [[ "$app_name" =~ $utility_app_regex ]]; then
      aerospace layout --window-id "$window_id" floating >/dev/null 2>&1 || true
      aerospace move-node-to-workspace --window-id "$window_id" 2 >/dev/null 2>&1 || true
    fi
  done

while IFS= read -r workspace; do
  [[ -n "$workspace" ]] || continue

  window_count="$(aerospace list-windows --workspace "$workspace" --count 2>/dev/null || echo 0)"
  if [[ "$window_count" == "0" ]]; then
    continue
  fi

  aerospace workspace "$workspace" >/dev/null 2>&1

  if [[ "$workspace" == "1" ]]; then
    aerospace list-windows --workspace 1 --format '%{window-id}|%{app-name}' 2>/dev/null |
      while IFS='|' read -r window_id app_name; do
        [[ -n "$window_id" ]] || continue
        aerospace layout --window-id "$window_id" tiling >/dev/null 2>&1 || true
      done

    aerospace layout tiles horizontal vertical >/dev/null 2>&1 || true
    aerospace flatten-workspace-tree --workspace 1 >/dev/null 2>&1 || true
    aerospace balance-sizes >/dev/null 2>&1 || true
  else
    aerospace list-windows --workspace "$workspace" --format '%{window-id}' 2>/dev/null |
      while IFS= read -r window_id; do
        [[ -n "$window_id" ]] || continue
        aerospace layout --window-id "$window_id" floating >/dev/null 2>&1 || true
      done
  fi
done < <(aerospace list-workspaces --all 2>/dev/null)

if [[ -n "$focused_workspace" ]]; then
  aerospace workspace "$focused_workspace" >/dev/null 2>&1 || true
fi
