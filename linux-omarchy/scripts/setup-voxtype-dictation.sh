#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p \
  "$HOME/.config/hypr" \
  "$HOME/.config/xremap" \
  "$HOME/.config/voxtype" \
  "$HOME/.config/systemd/user/voxtype.service.d" \
  "$HOME/.local/bin"

install -m 0644 "$ROOT_DIR/configs/hypr-bindings.conf" "$HOME/.config/hypr/bindings.conf"
install -m 0644 "$ROOT_DIR/configs/xremap-config.yml" "$HOME/.config/xremap/config.yml"
install -m 0644 "$ROOT_DIR/configs/voxtype-config.toml" "$HOME/.config/voxtype/config.toml"
install -m 0644 "$ROOT_DIR/configs/voxtype.service" "$HOME/.config/systemd/user/voxtype.service"
install -m 0644 "$ROOT_DIR/configs/voxtype-backend.conf" "$HOME/.config/systemd/user/voxtype.service.d/backend.conf"
install -m 0644 "$ROOT_DIR/configs/voxtype-gpu.conf" "$HOME/.config/systemd/user/voxtype.service.d/gpu.conf"
install -m 0755 "$ROOT_DIR/configs/hyprwhspr-compat" "$HOME/.local/bin/hyprwhspr"

systemctl --user daemon-reload
systemctl --user enable --now voxtype.service xremap.service

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
fi

echo "Voxtype dictation setup applied."
echo "Verify: systemctl --user is-enabled voxtype.service && systemctl --user is-active voxtype.service"
