# Shared shell helpers for surfacing Codex feature flags at launch.

_codex_features_raw() {
  command codex features list 2>/dev/null
}

_codex_features_subset() {
  local pattern
  pattern="${1:-^(codex_hooks|memories|tool_search|tool_suggest|js_repl|multi_agent|multi_agent_v2|tool_call_mcp_elicitation|shell_snapshot|unified_exec)[[:space:]]}"

  _codex_features_raw | grep -E "$pattern" || true
}

_codex_features_nondefault() {
  _codex_features_raw | awk '$2 != "stable" || $3 != "false"'
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
  local rows
  rows="$1"

  [ -n "$rows" ] || return 0

  printf '%s\n' "$rows" | awk '
    function add_row(stage, feature, enabled, row) {
      row = sprintf("%-30s %s", feature, enabled)
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
  local mode rows
  mode="${1:-${CODEX_FEATURE_MODE:-all}}"

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
      rows="$(_codex_features_nondefault)"
      ;;
    regex:*)
      rows="$(_codex_features_subset "${mode#regex:}")"
      ;;
    *)
      rows="$(_codex_features_subset "$mode")"
      ;;
  esac

  _codex_print_grouped_feature_table "$rows"
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
    printf 'Codex feature flags\n'
    codex_feature_banner
    printf '\n'
  fi

  command codex "$@"
}
