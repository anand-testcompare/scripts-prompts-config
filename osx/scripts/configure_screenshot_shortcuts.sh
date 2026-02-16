#!/usr/bin/env bash

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required. Install it with: brew install jq" >&2
  exit 1
fi

domain="com.apple.symbolichotkeys"
plist_path="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"

if [[ ! -f "$plist_path" ]]; then
  echo "Missing expected plist: $plist_path" >&2
  exit 1
fi

backup_path="$plist_path.bak-$(date +%Y%m%d-%H%M%S)"
cp "$plist_path" "$backup_path"

tmp_dir="$(mktemp -d /tmp/symbolichotkeys.XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT

src_plist="$tmp_dir/source.plist"
src_json="$tmp_dir/source.json"
out_json="$tmp_dir/updated.json"
out_plist="$tmp_dir/updated.plist"

defaults export "$domain" - > "$src_plist"
plutil -convert json -o "$src_json" "$src_plist"

jq '
  .AppleSymbolicHotKeys["28"] = {
    "enabled": false,
    "value": {
      "type": "standard",
      "parameters": [51, 20, 1179648]
    }
  }
  | .AppleSymbolicHotKeys["30"] = {
    "enabled": true,
    "value": {
      "type": "standard",
      "parameters": [52, 21, 393216]
    }
  }
  | .AppleSymbolicHotKeys["184"] = {
    "enabled": false,
    "value": {
      "type": "standard",
      "parameters": [53, 23, 1179648]
    }
  }
' "$src_json" > "$out_json"

plutil -convert xml1 -o "$out_plist" "$out_json"
defaults import "$domain" "$out_plist"
killall cfprefsd 2>/dev/null || true

echo "Updated screenshot shortcuts in $domain:"
defaults export "$domain" - \
  | plutil -convert json -o - - \
  | jq '{
      cmd_shift_3: .AppleSymbolicHotKeys["28"],
      screenshot_region: .AppleSymbolicHotKeys["30"],
      cmd_shift_5_toolbar: .AppleSymbolicHotKeys["184"]
    }'

echo "Backup saved to: $backup_path"
