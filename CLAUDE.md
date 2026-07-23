# CLAUDE.md

Claude Code should follow the repository guidance in `AGENTS.md`. This file mirrors the same repo-specific rules so Claude keeps the same workflow expectations even if it does not load `AGENTS.md`.

## Git Hygiene

- Avoid random stashes, local-only branches, and other local-only state hanging around after a task.
- Avoid important files existing only locally. If a file matters, commit it and get it into the remote; otherwise delete it or add a `.gitignore` rule in the same change.
- Prefer small, focused PRs that move real config changes into the remote quickly instead of batching unrelated local tweaks for later.

## Delegated Delivery

- After aligning with the user on large product or feature buckets, act as the delivery owner and delegate implementation work to an agent in a dedicated Herdr worktree.
- When implementation is ready, run a separate independent review agent. Route valid findings back through implementation, rerun affected and required tests, and keep iterating until review and CI are green.
- Use logical Graphite PRs or stacks for meaningful work. Once review and CI are green, merge autonomously with `gt merge`, verify the resulting `main` state and production deployment or runtime surfaces, and clean up completed Herdr worktrees and branches.
- Do not require the user to review or merge individual PRs. Escalate only genuine product or architecture decisions, unavailable credentials, or blockers that cannot be resolved independently.

## Repo Focus

- Prefer `osx/` and `linux-omarchy/` for current work.

## Change Rules

- Keep bash and zsh behavior in sync when editing shared shell config.
- Preserve safety-first restore behavior if touching backup/restore scripts.
- Keep committed configs free of machine-specific secrets unless a file is explicitly intended as a template.

## Herdr Delegation

- When sending a prompt or instruction through Herdr, use `herdr pane run <pane_id> "<prompt>"`; it submits the text and `Enter` atomically. Do not use `herdr agent send` for prompts because it intentionally writes literal text without submitting it. Use `agent send` only when unsubmitted text is explicitly desired, and verify the target pane after every send.

## Config Sync

- Commit only portable, intentional config copied from local machines.
- Do not commit auth tokens, OAuth state, machine-specific caches, history, or other ephemeral local data.
- If a useful local file should stay machine-specific, keep it out of the repo explicitly with `.gitignore`.

## Secrets

- Never commit real values in `.shell_secrets`, `.mcp.json`, or `.claude.json`.
- Use `.shell_secrets.template` for examples.
- Sensitive files should stay permissioned for user-only access (`600`).

## Useful Locations

- `osx/` - active macOS configs and scripts
- `linux-omarchy/` - active Linux/Omarchy docs and configs
- `universal/` - cross-platform scripts and shared tooling
