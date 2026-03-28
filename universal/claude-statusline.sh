#!/bin/sh

if ! command -v jq >/dev/null 2>&1; then
  printf 'Claude\n'
  exit 0
fi

input=$(cat)
tab=$(printf '\t')

IFS="$tab" read -r model cwd ctx_pct five_hr seven_day <<EOF
$(printf '%s' "$input" | jq -r '
  [
    .model.display_name // "Claude",
    .workspace.current_dir // .cwd // "",
    (.context_window.used_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.seven_day.used_percentage // "")
  ] | @tsv')
EOF

BLUE=$(printf '\033[0;34m')
CYAN=$(printf '\033[0;36m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[0;33m')
RED=$(printf '\033[0;31m')
MAGENTA=$(printf '\033[0;35m')
DIM=$(printf '\033[0;90m')
RESET=$(printf '\033[0m')

count_lines() {
  wc -l | tr -d ' '
}

file_mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || printf '0'
}

cache_is_stale() {
  [ ! -f "$1" ] && return 0
  now=$(date +%s)
  mtime=$(file_mtime "$1")
  [ $((now - mtime)) -gt "$2" ]
}

shorten_path() {
  path=$1
  [ -z "$path" ] && return 0

  case "$path" in
    "$HOME"*) path="~${path#$HOME}" ;;
  esac

  [ "$path" = "/" ] && {
    printf '/'
    return 0
  }

  path=${path%/}

  case "$path" in
    "~") printf '~' ;;
    "~/"*)
      rel=${path#~/}
      case "$rel" in
        */*)
          base=${rel##*/}
          parent=${rel%/*}
          parent=${parent##*/}
          printf '%s/%s' "$parent" "$base"
          ;;
        *)
          printf '~/%s' "$rel"
          ;;
      esac
      ;;
    */*)
      base=${path##*/}
      rest=${path%/*}
      case "$rest" in
        */*)
          parent=${rest##*/}
          printf '%s/%s' "$parent" "$base"
          ;;
        *)
          printf '%s/%s' "$rest" "$base"
          ;;
      esac
      ;;
    *)
      printf '%s' "$path"
      ;;
  esac
}

format_pct() {
  label=$1
  value=$2

  [ -z "$value" ] && return 0

  int_value=$(printf '%.0f' "$value" 2>/dev/null || printf '0')
  color=$GREEN

  if [ "$int_value" -ge 80 ]; then
    color=$RED
  elif [ "$int_value" -ge 50 ]; then
    color=$YELLOW
  fi

  printf '%s%s:%s%%%s' "$color" "$label" "$int_value" "$RESET"
}

git_branch=''
git_ahead=0
git_behind=0
git_staged=0
git_modified=0
git_untracked=0
git_conflicted=0

if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  cache_root=${TMPDIR:-/tmp}/claude-statusline-git
  cache_key=$(printf '%s' "$cwd" | cksum | awk '{print $1}')
  cache_file=$cache_root/$cache_key
  cache_max_age=5

  mkdir -p "$cache_root"

  if cache_is_stale "$cache_file" "$cache_max_age"; then
    git_branch=$(git -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null \
      || git -C "$cwd" rev-parse --short HEAD 2>/dev/null \
      || printf '')

    set -- $(git -C "$cwd" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null || printf '0 0')
    git_behind=${1:-0}
    git_ahead=${2:-0}
    git_staged=$(git -C "$cwd" diff --name-only --cached --diff-filter=ACDMRT 2>/dev/null | count_lines)
    git_modified=$(git -C "$cwd" diff --name-only --diff-filter=ACDMRT 2>/dev/null | count_lines)
    git_untracked=$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null | count_lines)
    git_conflicted=$(git -C "$cwd" diff --name-only --diff-filter=U 2>/dev/null | count_lines)

    printf '%s|%s|%s|%s|%s|%s|%s\n' \
      "$git_branch" \
      "$git_ahead" \
      "$git_behind" \
      "$git_staged" \
      "$git_modified" \
      "$git_untracked" \
      "$git_conflicted" > "$cache_file"
  fi

  IFS='|' read -r git_branch git_ahead git_behind git_staged git_modified git_untracked git_conflicted < "$cache_file"
fi

line=$(printf '%s%s%s' "$BLUE" "$model" "$RESET")

short_cwd=$(shorten_path "$cwd")
[ -n "$short_cwd" ] && line="$line $(printf '%s%s%s' "$CYAN" "$short_cwd" "$RESET")"

if [ -n "$git_branch" ]; then
  line="$line $(printf '%s%s%s' "$MAGENTA" "$git_branch" "$RESET")"

  [ "${git_staged:-0}" -gt 0 ] && line="$line $(printf '%s+%s%s' "$GREEN" "$git_staged" "$RESET")"
  [ "${git_modified:-0}" -gt 0 ] && line="$line $(printf '%s!%s%s' "$YELLOW" "$git_modified" "$RESET")"
  [ "${git_untracked:-0}" -gt 0 ] && line="$line $(printf '%s?%s%s' "$DIM" "$git_untracked" "$RESET")"
  [ "${git_conflicted:-0}" -gt 0 ] && line="$line $(printf '%s=%s%s' "$RED" "$git_conflicted" "$RESET")"
  [ "${git_ahead:-0}" -gt 0 ] && line="$line $(printf '%s^%s%s' "$GREEN" "$git_ahead" "$RESET")"
  [ "${git_behind:-0}" -gt 0 ] && line="$line $(printf '%sv%s%s' "$YELLOW" "$git_behind" "$RESET")"
fi

ctx_segment=$(format_pct ctx "$ctx_pct")
[ -n "$ctx_segment" ] && line="$line $ctx_segment"

five_hr_segment=$(format_pct 5h "$five_hr")
[ -n "$five_hr_segment" ] && line="$line $five_hr_segment"

seven_day_segment=$(format_pct 7d "$seven_day")
[ -n "$seven_day_segment" ] && line="$line $seven_day_segment"

printf '%b\n' "$line"
