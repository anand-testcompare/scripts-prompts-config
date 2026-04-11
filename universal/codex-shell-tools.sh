# Shared shell helpers for surfacing Codex feature flags at launch.

_codex_features_raw() {
  command codex features list 2>/dev/null
}

_codex_default_features_raw() {
  if [ -n "${_CODEX_DEFAULT_FEATURE_ROWS_CACHE-}" ]; then
    printf '%s\n' "$_CODEX_DEFAULT_FEATURE_ROWS_CACHE"
    return 0
  fi

  local cache_root tmp_home rows
  cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/codex-feature-defaults"

  mkdir -p "$cache_root" 2>/dev/null || return 0

  tmp_home="$(mktemp -d "$cache_root/home.XXXXXX" 2>/dev/null)" || return 0
  rows="$(
    HOME="$tmp_home" \
    XDG_CONFIG_HOME="$tmp_home/.config" \
    XDG_CACHE_HOME="$tmp_home/.cache" \
    command codex features list 2>/dev/null
  )"
  rm -rf "$tmp_home"

  [ -n "$rows" ] || return 0

  _CODEX_DEFAULT_FEATURE_ROWS_CACHE="$rows"
  printf '%s\n' "$rows"
}

_codex_features_subset() {
  local pattern
  pattern="${1:-^(codex_hooks|memories|tool_search|tool_suggest|js_repl|multi_agent|multi_agent_v2|tool_call_mcp_elicitation|shell_snapshot|unified_exec)[[:space:]]}"

  _codex_features_raw | grep -E "$pattern" || true
}

_codex_features_nondefault() {
  local default_rows current_rows
  default_rows="$1"
  current_rows="$(_codex_features_raw)"

  [ -n "$current_rows" ] || return 0

  if [ -z "$default_rows" ]; then
    printf '%s\n' "$current_rows" | awk '$2 != "stable" || $3 != "false"'
    return 0
  fi

  {
    printf '%s\n' "$default_rows"
    printf '__CURRENT__\n'
    printf '%s\n' "$current_rows"
  } | awk '
    $0 == "__CURRENT__" {
      in_current = 1
      next
    }

    {
      if (NF < 3) {
        next
      }

      enabled = $NF
      if (enabled != "true" && enabled != "false") {
        next
      }

      if (!in_current) {
        defaults[$1] = enabled
        next
      }

      if (!($1 in defaults) || defaults[$1] != enabled) {
        print $0
      }
    }
  '
}

_codex_print_feature_table() {
  local rows
  rows="$1"

  [ -n "$rows" ] || return 0

  printf '%-30s %-18s %s\n' "FEATURE" "STAGE" "ENABLED"
  printf '%-30s %-18s %s\n' "-------" "-----" "-------"
  printf '%s\n' "$rows"
}

_codex_print_grouped_feature_table() {
  local rows default_rows diff_color reset_color
  rows="$1"
  default_rows="$2"

  [ -n "$rows" ] || return 0

  if [ -t 1 ]; then
    diff_color=$'\033[32m'
    reset_color=$'\033[0m'
  else
    diff_color=""
    reset_color=""
  fi

  {
    printf '%s\n' "$default_rows"
    printf '__ROWS__\n'
    printf '%s\n' "$rows"
  } | awk -v diff_color="$diff_color" -v reset_color="$reset_color" '
    $0 == "__ROWS__" {
      in_rows = 1
      next
    }

    !in_rows {
      if (NF < 3) {
        next
      }

      enabled = $NF
      if (enabled != "true" && enabled != "false") {
        next
      }

      default_enabled[$1] = enabled
      default_count++
      next
    }

    function add_row(stage, feature, enabled, enabled_display, row, is_nondefault) {
      enabled_display = enabled

      is_nondefault = 0
      if (default_count > 0) {
        is_nondefault = (!(feature in default_enabled) || default_enabled[feature] != enabled)
      } else if (enabled == "true") {
        is_nondefault = 1
      }

      if (is_nondefault && diff_color != "") {
        enabled_display = diff_color enabled reset_color
      }

      row = sprintf("%-30s %s", feature, enabled_display)
      if (group_rows[stage] != "") {
        group_rows[stage] = group_rows[stage] "\n" row
      } else {
        group_rows[stage] = row
      }
      group_counts[stage]++
    }

    {
      if (NF < 3) {
        next
      }

      enabled = $NF
      if (enabled != "true" && enabled != "false") {
        next
      }

      feature = $1
      stage = $2
      for (i = 3; i < NF; i++) {
        stage = stage " " $i
      }

      add_row(stage, feature, enabled)
      seen[stage] = 1
    }

    END {
      ordered[1] = "stable"
      ordered[2] = "experimental"
      ordered[3] = "under development"
      ordered[4] = "deprecated"
      ordered[5] = "removed"

      for (i = 1; i <= 5; i++) {
        stage = ordered[i]
        if (!(stage in seen) || !seen[stage]) {
          continue
        }

        printf "%s (%d)\n", toupper(stage), group_counts[stage]
        printf "%-30s %s\n", "FEATURE", "ENABLED"
        printf "%-30s %s\n", "-------", "-------"
        printf "%s\n\n", group_rows[stage]
        printed[stage] = 1
      }

      for (stage in seen) {
        if (!seen[stage] || printed[stage]) {
          continue
        }

        printf "%s (%d)\n", toupper(stage), group_counts[stage]
        printf "%-30s %s\n", "FEATURE", "ENABLED"
        printf "%-30s %s\n", "-------", "-------"
        printf "%s\n\n", group_rows[stage]
      }
    }
  '
}

codex_feature_banner() {
  local mode rows default_rows
  mode="${1:-${CODEX_FEATURE_MODE:-all}}"
  default_rows="$(_codex_default_features_raw)"

  case "$mode" in
    all)
      rows="$(_codex_features_raw)"
      ;;
    hidden)
      rows="$(_codex_features_subset '^(codex_hooks|memories)[[:space:]]')"
      ;;
    subset)
      rows="$(_codex_features_subset)"
      ;;
    nondefault)
      rows="$(_codex_features_nondefault "$default_rows")"
      ;;
    regex:*)
      rows="$(_codex_features_subset "${mode#regex:}")"
      ;;
    *)
      rows="$(_codex_features_subset "$mode")"
      ;;
  esac

  _codex_print_grouped_feature_table "$rows" "$default_rows"
}

codex_hidden_features() {
  codex_feature_banner hidden
}

codex_nondefault_features() {
  codex_feature_banner nondefault
}

codex_all_features() {
  codex_feature_banner all
}

_codex_should_show_banner() {
  case "${1-}" in
    ""|--*|-*)
      return 0
      ;;
    exec|review|login|logout|mcp|mcp-server|app-server|completion|sandbox|debug|apply|resume|fork|cloud|features|help)
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

codex() {
  if [ -t 0 ] && [ -t 1 ] && [ "${CODEX_FEATURE_BANNER:-1}" = "1" ] && _codex_should_show_banner "${1-}"; then
    printf 'Codex feature flags (green = differs from default)\n'
    codex_feature_banner
    printf '\n'
  fi

  command codex "$@"
}
