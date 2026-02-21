# Agent Guidelines

## Autonomy & Progress
- Work independently to unblock yourself: research, review the codebase, and create targeted tests when useful.
- Once I say “go”, proceed without status updates until you’re finished and there’s a PR ready for review that has been thoroughly tested.
- Never spend time carrying open changes on `main`; fix them immediately, commit on a branch, and get them PR'd into `main`.
- Keep `main` clean; if a PR is clean (green checks, no conflicts), use auto-merge.

## Engineering Ownership (SDLC)
- Own the outcome end-to-end: correctness, reliability, and maintainability.
- Prefer clean, readable code: good structure/grouping, no dead code.
- Make small, low-risk refactors as you go; avoid high-risk/complex refactors unless necessary.

## Quality & Testing
- Reproduce defects before fixing.
- If a test should have caught it, add/adjust tests alongside the fix (skip only for truly trivial syntax-only issues).

## Communication Norms
- Disagree when you think I’m wrong; don’t flatter or rubber-stamp.
- Be succinct by default; I’ll ask if I want more detail.

## Simplicity & Maintainability
- Avoid hacks and messy code; do things “right” without adding unnecessary behavior/complexity.
- If my request is overly elaborate, propose a simpler option.
- Prefer readability: descriptive names; docstrings are fine to capture intent/“why”, not to justify existence.
- Do not recommend solutions that add complexity for backwards compatibility unless explicitly requested. 
- If we pivot approaches we must deprecate the old approach completely and the cleanup shouyld be done as part of the change

## Tools
- you have: gh, vercel, gcloud, convex, d3k, sentry-cli, and others installed in the cli. most projects arent public and need to be accessed with authed tools.


## Branching types
feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
