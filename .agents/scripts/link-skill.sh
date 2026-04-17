#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./.agents/scripts/link-skill.sh <skill-name> [<skill-name> ...]
  ./.agents/scripts/link-skill.sh --all

Creates symlinks in ~/.agents/skills that point at this repository's .agents/skills entries.
EOF
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "${script_dir}/../.." && pwd -P)"
source_root="${repo_root}/.agents/skills"
target_root="${HOME}/.agents/skills"

if [ "$#" -eq 0 ]; then
  usage >&2
  exit 1
fi

if [ "${1}" = "--all" ]; then
  if [ "$#" -ne 1 ]; then
    usage >&2
    exit 1
  fi
  skills=()
  while IFS= read -r skill; do
    skills+=("${skill}")
  done < <(find "${source_root}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
else
  skills=("$@")
fi

mkdir -p "${target_root}"

for skill in "${skills[@]}"; do
  source_path="${source_root}/${skill}"
  target_path="${target_root}/${skill}"

  if [ ! -d "${source_path}" ]; then
    echo "missing repo-backed skill: ${skill}" >&2
    exit 1
  fi

  if [ -e "${target_path}" ] && [ ! -L "${target_path}" ]; then
    echo "refusing to replace non-symlink target: ${target_path}" >&2
    exit 1
  fi

  rm -f "${target_path}"
  ln -s "${source_path}" "${target_path}"
  echo "linked ${target_path} -> ${source_path}"
done
