#!/usr/bin/env bash
set -euo pipefail

readonly UPSTREAM_URL="https://github.com/davis7dotsh/my-pi-setup.git"
readonly UPSTREAM_COMMIT="797eaf6d6f178759cf7aabde927ef15c91346e7e"
readonly DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly CHECKOUT_DIR="${PI_SUBAGENTS_CHECKOUT_DIR:-$DATA_HOME/pi-packages/davis7-my-pi-setup}"
readonly PI_AGENT_DIR="${PI_AGENT_DIR:-$HOME/.pi/agent}"

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

if [[ -e "$CHECKOUT_DIR" && ! -d "$CHECKOUT_DIR/.git" ]]; then
  fail "$CHECKOUT_DIR exists but is not the managed upstream checkout"
fi

if [[ ! -d "$CHECKOUT_DIR/.git" ]]; then
  mkdir -p "$(dirname "$CHECKOUT_DIR")"
  git clone --no-checkout "$UPSTREAM_URL" "$CHECKOUT_DIR"
else
  current_origin="$(git -C "$CHECKOUT_DIR" remote get-url origin)"
  case "$current_origin" in
    "$UPSTREAM_URL"|git@github.com:davis7dotsh/my-pi-setup.git) ;;
    *) fail "$CHECKOUT_DIR has unexpected origin: $current_origin" ;;
  esac

  if [[ -n "$(git -C "$CHECKOUT_DIR" status --porcelain --untracked-files=no)" ]]; then
    fail "$CHECKOUT_DIR has tracked local changes; preserve or discard them before reinstalling"
  fi
fi

git -C "$CHECKOUT_DIR" fetch --depth=1 origin "$UPSTREAM_COMMIT"
git -C "$CHECKOUT_DIR" -c advice.detachedHead=false checkout --detach "$UPSTREAM_COMMIT"

readonly EXTENSION_SOURCE="$CHECKOUT_DIR/extensions/subagents"
readonly SKILL_SOURCE="$CHECKOUT_DIR/skills/subagents"
[[ -f "$EXTENSION_SOURCE/index.ts" ]] || fail "upstream subagents extension is missing"
[[ -f "$SKILL_SOURCE/SKILL.md" ]] || fail "upstream subagents skill is missing"

# The nested package's prepare hook only patches development-time TypeScript
# declarations. Runtime needs Effect and the Claude Agent SDK, so install
# production dependencies without lifecycle scripts.
npm ci --prefix "$EXTENSION_SOURCE" --omit=dev --ignore-scripts

install_link() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"
  if [[ -L "$target" && "$(readlink -f "$target")" == "$(readlink -f "$source")" ]]; then
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local backup="${target}.bak-$(date +%Y%m%d-%H%M%S)"
    mv "$target" "$backup"
    printf 'Backed up %s to %s\n' "$target" "$backup"
  fi

  ln -s "$source" "$target"
}

install_link "$EXTENSION_SOURCE" "$PI_AGENT_DIR/extensions/subagents"
install_link "$SKILL_SOURCE" "$PI_AGENT_DIR/skills/subagents"

printf 'Installed Davis subagents at commit %s.\n' "$UPSTREAM_COMMIT"
printf 'Restart Pi or run /reload in an existing Pi session.\n'
