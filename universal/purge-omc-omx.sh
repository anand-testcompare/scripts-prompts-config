#!/usr/bin/env bash
set -euo pipefail

for scope in user local project; do
  if command -v claude >/dev/null 2>&1; then
    claude plugin uninstall oh-my-claudecode@omc --scope "$scope" --yes >/dev/null 2>&1 || true
    claude plugin uninstall oh-my-claudecode --scope "$scope" --yes >/dev/null 2>&1 || true
  fi
done

if command -v npm >/dev/null 2>&1; then
  npm uninstall --global oh-my-claude-sisyphus oh-my-claudecode oh-my-codex >/dev/null 2>&1 || true
fi
if command -v pnpm >/dev/null 2>&1; then
  pnpm remove --global oh-my-claude-sisyphus oh-my-claudecode oh-my-codex >/dev/null 2>&1 || true
fi

rm -rf \
  "$HOME/.claude/plugins/oh-my-claudecode" \
  "$HOME/.claude/plugins/data/oh-my-claudecode" \
  "$HOME/.claude-omc" \
  "$HOME/.omc" \
  "$HOME/.omx" \
  "$HOME/.config/omc" \
  "$HOME/.config/omx" \
  "$HOME/.local/state/omc" \
  "$HOME/.local/state/omx"
rm -f \
  "$HOME/.claude/.omc-config.json" \
  "$HOME/.claude/hud/omc-hud.mjs" \
  "$HOME/.local/bin/omc" \
  "$HOME/.local/bin/omx"

find "$HOME/.cache/claude-cli-nodejs" -type d \
  -name 'mcp-logs-plugin-oh-my-claudecode*' -prune -exec rm -rf {} + \
  2>/dev/null || true

settings="$HOME/.claude/settings.json"
if [[ -f "$settings" ]] && command -v jq >/dev/null 2>&1; then
  mode="$(stat -c '%a' "$settings" 2>/dev/null || stat -f '%Lp' "$settings")"
  tmp="$(mktemp)"
  jq '
    if .enabledPlugins then
      .enabledPlugins |= with_entries(
        select(.key | test("oh-my-claudecode|oh-my-claude-sisyphus|(^|@)om[ctx]($|@)"; "i") | not)
      )
    else . end |
    if ((.statusLine.command? // "") | test("oh-my-claude|claude-omc|omc-hud|omx"; "i"))
    then del(.statusLine)
    else . end
  ' "$settings" > "$tmp"
  install -m "$mode" "$tmp" "$settings"
  rm -f "$tmp"
fi

python - "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.zprofile" <<'PY'
from pathlib import Path
import re
import sys

for raw_path in sys.argv[1:]:
    path = Path(raw_path)
    if not path.is_file():
        continue
    text = path.read_text()
    text = re.sub(
        r"(?:^|\n)# Launch Claude Code with oh-my-claudecode:.*?\n"
        r"# session, plain `claude` runs vanilla \(the default in settings\.json\)\.\n"
        r"omc\(\) \{.*?^\}\n+",
        "\n",
        text,
        flags=re.MULTILINE | re.DOTALL,
    )
    text = re.sub(
        r"^.*(?:CLAUDE_CONFIG_DIR=.*\.claude-omc|OMC_STATE_DIR|oh-my-claudecode|oh-my-claude-sisyphus).*$\n?",
        "",
        text,
        flags=re.MULTILINE,
    )
    path.write_text(text)
PY

rmdir "$HOME/.claude/hud" 2>/dev/null || true
printf '%s\n' 'Purged active OMC/OMX packages, plugins, wrappers, state, caches, and shell configuration.'
