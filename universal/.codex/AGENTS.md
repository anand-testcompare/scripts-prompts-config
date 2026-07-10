# Agent Guidelines

## Autonomy & Progress

- Work independently to unblock yourself: research, review the codebase, iterate on failures, and create targeted tests when useful.
- Once I say "go", proceed without status updates until you're finished and there's a PR ready for review that has been thoroughly tested.

## Engineering Ownership (SDLC)

- Own the outcome end-to-end: correctness, reliability, and maintainability.
- Prefer clean, readable code: good structure/grouping, no dead code.
- Make low-risk refactors as you go; avoid high-risk/complex refactors unless necessary.

## Delegated Delivery

- After aligning with the user on large product or feature buckets, act as the delivery owner and delegate implementation work to an agent in a dedicated Herdr worktree.
- When implementation is ready, run a separate independent review agent. Route valid findings back through implementation, rerun affected and required tests, and keep iterating until review and CI are green.
- Use logical Graphite PRs or stacks for meaningful work. Once review and CI are green, merge autonomously with `gt merge`, verify the resulting `main` state and production deployment or runtime surfaces, and clean up completed Herdr worktrees and branches.
- Do not require the user to review or merge individual PRs. Escalate only genuine product or architecture decisions, unavailable credentials, or blockers that cannot be resolved independently.

## Agent Model Selection

- Use Codex `gpt-5.6-sol` for delegated planning, implementation, and review by default. Do not launch older Codex models such as `gpt-5.5`.
- Set reasoning effort explicitly when launching an agent: use `low` or `medium` for simple, bounded work and `xhigh` for hard, broad, or high-risk work.
- Claude models, including Opus, are optional only for genuinely UI/UX-heavy work. Keep non-UI implementation and review on Codex `gpt-5.6-sol`.

## Quality & Testing

- Reproduce defects before fixing.
- If a test should have caught it, add/adjust tests alongside the fix (skip only for truly trivial syntax-only issues).

## Communication Norms

- Disagree when you think I'm wrong; don't flatter or rubber-stamp.
- Be succinct by default; I'll ask if I want more detail.

## Simplicity & Maintainability

- Avoid hacks and messy code; do things "right" without adding unnecessary behavior/complexity.
- If my request is overly elaborate, propose a simpler option.
- Prefer readability: descriptive names; docstrings are fine to capture intent/"why", not to justify existence.
- Do not recommend solutions that add complexity for backwards compatibility unless explicitly requested.
- If we pivot approaches we must deprecate the old approach completely and the cleanup shouyld be done as part of the change

## Tools

- you have: gh, vercel, gcloud, convex, d3k, sentry-cli, and others installed in the cli. most projects arent public and need to be accessed with authed tools.
- When sending a prompt or instruction through Herdr, use `herdr pane run <pane_id> "<prompt>"`; it submits the text and `Enter` atomically. Do not use `herdr agent send` for prompts because it intentionally writes literal text without submitting it. Use `agent send` only when unsubmitted text is explicitly desired, and verify the target pane after every send.

## Git Workflow

- Avoid leaving random stashes, local-only branches, or other local-only state behind when the task is complete.
- Avoid important files existing only on the current machine. If a file matters, commit it and get it into the remote; otherwise delete it or add an appropriate `.gitignore` rule.
- Prefer Graphite (`gt`) for anything beyond an inconsequential change: create/update logical stacked PRs instead of pushing directly to trunk or leaving meaningful work only local.
- Prefer logical PRs that move complete, proven functionality into the remote. Do not split work into tiny PRs just to appear done.
- If you temporarily stash or branch to get work done, clean that up before finishing unless the user explicitly asks to keep it around.
- Use semantic branch prefixes that describe the work, such as `feat/`, `fix/`, `docs/`, `refactor/`, `chore/`, or `test/`. Do not use `codex/` as an agent-signature branch prefix.

## Memory

- Store temporary data in repository `.memory/` directory (gitignored, but add a .ignore with !.memory/** so the agent can still view it). Create the .memory folder if it doesn't exist, do not use /tmp
