#!/usr/bin/env bash

set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

staged=0
unstaged=0
untracked=0

while IFS= read -r line; do
  [ -n "$line" ] || continue
  x="${line:0:1}"
  y="${line:1:1}"

  if [ "$x" = "?" ] && [ "$y" = "?" ]; then
    untracked=$((untracked + 1))
    continue
  fi

  if [ "$x" != " " ]; then
    staged=$((staged + 1))
  fi

  if [ "$y" != " " ]; then
    unstaged=$((unstaged + 1))
  fi
done < <(git status --porcelain=v1)

ahead=0
behind=0
branch_line="$(git status --porcelain=v1 --branch | sed -n '1p')"

if [[ "$branch_line" =~ ahead[[:space:]]([0-9]+) ]]; then
  ahead="${BASH_REMATCH[1]}"
fi

if [[ "$branch_line" =~ behind[[:space:]]([0-9]+) ]]; then
  behind="${BASH_REMATCH[1]}"
fi

mkdir -p "$HOME/.codex/.tmp"
printf '%s cwd=%s staged=%s unstaged=%s untracked=%s ahead=%s behind=%s\n' \
  "$(date -Iseconds)" "$PWD" "$staged" "$unstaged" "$untracked" "$ahead" "$behind" \
  >> "$HOME/.codex/.tmp/session-start-hook.log"

printf 'Git status on session start: %s staged, %s unstaged, %s untracked, %s ahead, %s behind.\n' \
  "$staged" "$unstaged" "$untracked" "$ahead" "$behind"
