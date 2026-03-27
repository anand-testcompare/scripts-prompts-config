# Repository Workflow

This repository exists to keep working configs, scripts, and prompts reproducible across machines. Do not leave meaningful config work stranded only on the current laptop.

## Git Hygiene

- Avoid random stashes, local-only branches, and other local-only state hanging around after a task.
- Avoid important files existing only locally. If a file matters, commit it and get it into the remote; otherwise delete it or add a `.gitignore` rule in the same change.
- Prefer small, focused PRs that move real config changes into the remote quickly instead of batching unrelated local tweaks for later.

## Repo Focus

- Prefer `osx/` and `linux-omarchy/` for current work.
- Treat `linux-popos/` as legacy unless the task explicitly targets it.

## Change Rules

- Keep bash and zsh behavior in sync when editing shared shell config.
- Preserve safety-first restore behavior if touching backup/restore scripts.
- Keep committed configs free of machine-specific secrets unless a file is explicitly intended as a template.

## Config Sync

- When copying settings from home-directory tools into this repo, commit only portable and intentional config.
- Do not commit auth tokens, OAuth state, machine-specific caches, history, or other ephemeral local data.
- If a useful local file should stay machine-specific, keep it out of the repo explicitly with `.gitignore`.

## Secrets

- Never commit real values in `.shell_secrets`, `.mcp.json`, or `.claude.json`.
- Use `.shell_secrets.template` for examples.
- Sensitive files should stay permissioned for user-only access (`600`).

## Useful Locations

- `osx/` - active macOS configs and scripts
- `linux-omarchy/` - active Linux/Omarchy docs and configs
- `linux-popos/` - legacy backup/restore flow and shell-sync prompt
- `universal/` - cross-platform scripts and shared tooling
