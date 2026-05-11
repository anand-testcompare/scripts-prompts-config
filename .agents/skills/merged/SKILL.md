---
name: merged
description: Post-merge reset, verification, deployment/release check, local branch cleanup, and next-work recommendation after a PR or change is merged. Use when the user says merged, $merged, /merged, asks to switch to main/master and pull, verify production after merge, or get ready for the next slice.
---

# Merged

## Objective

A PR/change was just merged. Move the local checkout to the merged primary branch, prove the landed state is healthy with lightweight high-signal checks, verify relevant deployment/release follow-through, clean up safe stale branch state, and recommend the next sensible slice.

## Default Workflow

1. Read repo instructions first when present (`AGENTS.md`, `CLAUDE.md`, repo README/TODO/work tracker) so post-merge verification matches the project.
2. Inspect current git state before switching branches: `git status --short --branch`, `git branch --show-current`, and `git remote -v`.
3. If unrelated uncommitted work exists, preserve it before switching only when safe. Prefer a narrow stash of conflicting files with a clear message; stop and ask only when ownership or safety is ambiguous.
4. Resolve the primary branch from GitHub/default-branch metadata when possible; otherwise use `main`, then `master` if that is the repo default.
5. Confirm the merge when a PR number, URL, or current branch PR is discoverable. Prefer `gh pr view` for `state`, `mergedAt`, `mergeCommit`, `headRefName`, `baseRefName`, and check/merge status.
6. Switch to the primary branch and fast-forward only: `git switch <primary>` then `git pull --ff-only origin <primary>`.
7. Verify the landed commit locally with lightweight project-appropriate checks: typecheck/lint/test/build/smoke commands that are already documented or obvious from package scripts, justfiles, Makefiles, or CI.
8. Verify post-merge CI/deploy/release status when applicable. Use installed CLIs first: `depot` for Depot, `gh` for GitHub Actions/checks/releases, `vercel` for Vercel, `wrangler` for Cloudflare Workers, `gcloud` for GCP, or the repo's documented deploy surface.
9. If the repo has a relevant deployed app/service, do a simple smoke check of the live or production URL. If no deploy applies, say why.
10. Delete the old local feature branch only after the merge is confirmed and the branch is not current. Use non-destructive deletion first (`git branch -d`); use force deletion only if the remote PR is conclusively merged/squashed and there is no unique local work.
11. End with a concise status summary: primary branch, pulled commit, local verification, remote/deploy verification, cleanup done/skipped, and one recommended next feature/change grounded in current repo state.

## Guardrails

- Do not use `git reset --hard`, forced checkouts, or destructive cleanup unless the user explicitly approves.
- Do not assume a PR merged just because checks are green. Verify the merge state or merge commit when possible.
- Do not pull with merge commits; use `--ff-only` and stop on divergence.
- Do not hide uncommitted user work. Preserve or ask before branch switches that would overwrite it.
- Do not run exhaustive suites by default when a documented lightweight post-merge check is enough.
- Do not start implementing the next recommended slice unless the user asks.

## Useful Commands

```bash
git status --short --branch
git branch --show-current
gh repo view --json defaultBranchRef
gh pr view --json number,url,state,mergedAt,mergeCommit,headRefName,baseRefName,headRefOid,mergeStateStatus
git switch main
git pull --ff-only origin main
gh run list --limit 10
gh pr checks <pr-number-or-url>
```

## Prompt Equivalent

If a tool only supports prompt snippets, use:

```text
Switch to the primary branch, pull the latest changes with fast-forward only, and do a lightweight post-merge check. Verify any production/deployment/release actions, including a smoke test if there is a relevant deployed app or service; otherwise note why it does not apply. Preserve unrelated local work, clean up only safe stale branch state, then suggest one sensible next feature or improvement grounded in the current repo state.
```
