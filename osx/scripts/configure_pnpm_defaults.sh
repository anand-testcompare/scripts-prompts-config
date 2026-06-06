#!/usr/bin/env bash
set -euo pipefail

# Make pnpm 11 the standard package manager on macOS machines and apply the
# persistent pnpm security defaults. This intentionally avoids npm release-age
# workarounds; pnpm owns the policy directly.

PNPM_VERSION="${PNPM_VERSION:-11.5.1}"
PNPM_CONFIG_DIR="${HOME}/Library/Preferences/pnpm"
PNPM_CONFIG_FILE="${PNPM_CONFIG_DIR}/config.yaml"
PNPM_HOME_DIR="${PNPM_HOME:-${HOME}/Library/pnpm}"

if ! command -v corepack >/dev/null 2>&1; then
  echo "error: corepack is required. Install/update Node first." >&2
  exit 1
fi

corepack enable
corepack prepare "pnpm@${PNPM_VERSION}" --activate

mkdir -p "${PNPM_CONFIG_DIR}" "${PNPM_HOME_DIR}"
cat > "${PNPM_CONFIG_FILE}" <<YAML
# scripts-prompts-config managed pnpm defaults
# pnpm 11 reads user config from ~/Library/Preferences/pnpm/config.yaml on macOS.
globalBinDir: ${PNPM_HOME_DIR}
minimumReleaseAge: 1440
minimumReleaseAgeExclude: '["@nyrra/*","@openontology/*","@openai/*","@shpitdev/*","@sketchi-app/*","@pnpm/*"]'
blockExoticSubdeps: true
strictDepBuilds: true
YAML

# Remove the old npm-wrapper/XDG reference file if it exists from prior setup.
rm -f "${HOME}/.config/pnpm/rc"

# Keep npm config minimal; pnpm is the default package manager and owns release-age policy.
cat > "${HOME}/.npmrc" <<'NPMRC'
# Prefer pnpm 11 for package management. Do not put release-age policy here.
audit=false
fund=false
NPMRC
chmod 600 "${HOME}/.npmrc" || true

printf 'pnpm version: '
pnpm --version
printf 'pnpm config: %s\n' "${PNPM_CONFIG_FILE}"
