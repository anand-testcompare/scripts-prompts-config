#!/usr/bin/env bash

set -euo pipefail

if ! command -v aerospace >/dev/null 2>&1; then
  exit 0
fi

# Give macOS a moment to restore login items before forcing workspaces back
# into a tiled layout. This reduces the "stacked on top of each other after
# reboot" failure mode when apps re-open before AeroSpace finishes settling.
sleep "${AEROSPACE_STARTUP_DELAY:-4}"

focused_workspace="$(aerospace list-workspaces --focused 2>/dev/null | head -n 1 || true)"

while IFS= read -r workspace; do
  [[ -n "$workspace" ]] || continue

  window_count="$(aerospace list-windows --workspace "$workspace" --count 2>/dev/null || echo 0)"
  if [[ "$window_count" == "0" ]]; then
    continue
  fi

  aerospace workspace "$workspace" >/dev/null 2>&1
  aerospace layout tiles horizontal vertical >/dev/null 2>&1
  aerospace flatten-workspace-tree >/dev/null 2>&1
  aerospace balance-sizes >/dev/null 2>&1
done < <(aerospace list-workspaces --all 2>/dev/null)

if [[ -n "$focused_workspace" ]]; then
  aerospace workspace "$focused_workspace" >/dev/null 2>&1
fi
