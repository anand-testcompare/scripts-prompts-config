#!/usr/bin/env bash
set -euo pipefail

LINUX_OMARCHY_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd -- "$LINUX_OMARCHY_DIR/.." && pwd)"

SOURCE_LIST_FILE="${SOURCE_LIST_FILE:-$LINUX_OMARCHY_DIR/keychron-omarchy-config-files.txt}"
BACKUPS_DIR="${BACKUPS_DIR:-$REPO_ROOT/backups}"

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$BACKUPS_DIR/omarchy-dotfiles-$timestamp"

mkdir -p "$backup_dir"

manifest="$backup_dir/manifest.txt"
copied_txt="$backup_dir/copied.txt"
missing_txt="$backup_dir/missing.txt"
skipped_txt="$backup_dir/skipped.txt"

{
  echo "Backup created: backups/omarchy-dotfiles-$timestamp"
  echo "Source list: linux-omarchy/keychron-omarchy-config-files.txt"
  echo "Timestamp: $timestamp"
  echo
} >"$manifest"

: >"$copied_txt"
: >"$missing_txt"
: >"$skipped_txt"

copy_rel_to_home() {
  local expanded_path="$1"
  local rel
  local display

  if [[ "$expanded_path" == "$HOME" ]]; then
    rel="."
    display="~"
  elif [[ "$expanded_path" == "$HOME/"* ]]; then
    rel="${expanded_path#"$HOME"/}"
    display="~/$rel"
  else
    echo "$expanded_path" >>"$skipped_txt"
    return 0
  fi

  if [[ ! -e "$expanded_path" ]]; then
    echo "$display" >>"$missing_txt"
    return 0
  fi

  # Preserve the path relative to $HOME inside the backup folder, matching prior backups:
  # e.g. ~/.config/hypr/bindings.conf -> $backup_dir/.config/hypr/bindings.conf
  rsync -a --relative "$HOME/./$rel" "$backup_dir/" >/dev/null
  echo "$display" >>"$copied_txt"
}

while IFS= read -r line || [[ -n "$line" ]]; do
  # Strip comments and whitespace.
  line="${line%%#*}"
  line="${line%"${line##*[![:space:]]}"}" # rtrim
  line="${line#"${line%%[![:space:]]*}"}" # ltrim
  [[ -z "$line" ]] && continue

  # Expand ~ only (the list file uses ~/.config/... style paths).
  # Don't use `${line#~/}` here: unquoted `~/` can be tilde-expanded by the shell.
  if [[ "$line" == "~/"* ]]; then
    copy_rel_to_home "$HOME/${line:2}"
  else
    # If someone puts absolute paths in here, keep it explicit and skip by default.
    echo "$line" >>"$skipped_txt"
  fi
done <"$SOURCE_LIST_FILE"

# Extras: take a full snapshot of the key Omarchy directories that tend to drift over time.
extras=(
  "$HOME/.config/omarchy"
  "$HOME/.config/hypr"
  "$HOME/.config/waybar"
)

{
  echo "Extras:"
  printf "  %s\n" "~/.config/omarchy" "~/.config/hypr" "~/.config/waybar"
  echo
} >>"$manifest"

for p in "${extras[@]}"; do
  copy_rel_to_home "$p"
done

{
  echo "Copied ($(wc -l <"$copied_txt")):"
  sed 's/^/  /' "$copied_txt"
  echo
  echo "Missing (not found on disk) ($(wc -l <"$missing_txt")):"
  sed 's/^/  /' "$missing_txt"
  echo
  echo "Skipped ($(wc -l <"$skipped_txt")):"
  sed 's/^/  /' "$skipped_txt"
} >>"$manifest"

echo "$backup_dir"
