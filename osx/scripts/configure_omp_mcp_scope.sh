#!/usr/bin/env bash
set -euo pipefail

# Scope OMP's cross-tool MCP discovery so Larry generators are only available
# inside the Codestrap workspace, and remove the Vercel Claude plugin cache.
#
# OMP discovers user-level Windsurf MCP servers from:
#   ~/.codeium/windsurf/mcp_config.json
# so keep that file empty globally. OMP also discovers project-level Windsurf
# MCP servers from:
#   <cwd>/.windsurf/mcp_config.json
# so create the Larry MCP config at ~/Development/codestrap/.windsurf/mcp_config.json.
#
# Secrets are intentionally not stored in this repo. If you want the generated
# project config to include LARRY_API_KEY, export LARRY_API_KEY before running.

HOME_DIR="${HOME}"
CODESTRAP_DIR="${CODESTRAP_DIR:-${HOME_DIR}/Development/codestrap}"
GLOBAL_WINDSURF_MCP="${HOME_DIR}/.codeium/windsurf/mcp_config.json"
CODESTRAP_WINDSURF_MCP="${CODESTRAP_DIR}/.windsurf/mcp_config.json"
FDF_DIR="${CODESTRAP_DIR}/foundry-developer-foundations"
DOTENV_BIN="${FDF_DIR}/node_modules/.bin/dotenv"
DOTENV_FILE="${FDF_DIR}/.env.local"
VERCEL_PLUGIN_CACHE="${HOME_DIR}/.claude/plugins/cache/claude-plugins-official/vercel"
OMP_DB="${HOME_DIR}/.omp/agent/agent.db"

mkdir -p "$(dirname "${GLOBAL_WINDSURF_MCP}")"
cat > "${GLOBAL_WINDSURF_MCP}" <<'JSON'
{
  "mcpServers": {}
}
JSON

if [[ -d "${CODESTRAP_DIR}" ]]; then
  mkdir -p "$(dirname "${CODESTRAP_WINDSURF_MCP}")"

  if [[ -n "${LARRY_API_KEY:-}" ]]; then
    cat > "${CODESTRAP_WINDSURF_MCP}" <<JSON
{
  "mcpServers": {
    "larry-node-generators": {
      "command": "${DOTENV_BIN}",
      "args": [
        "-e",
        "${DOTENV_FILE}",
        "--",
        "npx",
        "-y",
        "@codestrap/node-generators@latest"
      ],
      "env": {
        "LARRY_API_URL": "${LARRY_API_URL:-https://larry-as-a-service.vercel.app/}",
        "LARRY_API_KEY": "${LARRY_API_KEY}"
      }
    }
  }
}
JSON
  else
    cat > "${CODESTRAP_WINDSURF_MCP}" <<JSON
{
  "mcpServers": {
    "larry-node-generators": {
      "command": "${DOTENV_BIN}",
      "args": [
        "-e",
        "${DOTENV_FILE}",
        "--",
        "npx",
        "-y",
        "@codestrap/node-generators@latest"
      ]
    }
  }
}
JSON
  fi
else
  echo "warning: Codestrap directory not found: ${CODESTRAP_DIR}; skipped project Larry MCP config" >&2
fi

rm -rf "${VERCEL_PLUGIN_CACHE}"

# Drop stale MCP tool cache entries so changes apply cleanly on next OMP launch.
if command -v sqlite3 >/dev/null 2>&1 && [[ -f "${OMP_DB}" ]]; then
  sqlite3 "${OMP_DB}" \
    "delete from cache where key in ('mcp_tools:larry-node-generators','mcp_tools:vercel:vercel','mcp_tools:vercel');" \
    >/dev/null 2>&1 || true
fi

echo "Configured global Windsurf MCP as empty: ${GLOBAL_WINDSURF_MCP}"
if [[ -f "${CODESTRAP_WINDSURF_MCP}" ]]; then
  echo "Configured Codestrap Larry MCP: ${CODESTRAP_WINDSURF_MCP}"
fi
echo "Removed Vercel Claude plugin cache: ${VERCEL_PLUGIN_CACHE}"
