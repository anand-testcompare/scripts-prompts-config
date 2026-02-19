---
name: preview-cleanup
description: Clean up stale preview resources (Vercel preview deployments, preview aliases/domains, and related CI noise) only when explicitly requested. Do not use proactively for routine deploy/debug tasks.
---

# Preview Cleanup Playbook

Use this skill only when the user asks to clean up preview artifacts/resources.

## Scope Guardrails

1. Confirm target scope first: repo/project, branch pattern, and age window.
2. Prefer dry-run/listing commands before any delete operation.
3. Never remove active production resources.
4. If target criteria are ambiguous, ask for confirmation before deleting.

## Common Workflow

1. Inspect preview inventory.
2. Identify safe stale targets using explicit rules (age + branch state + deployment state).
3. Delete stale preview resources in small batches.
4. Re-check inventory and summarize exactly what was removed.

## Vercel Commands

```bash
# List recent deployments for the linked project
vercel ls --yes

# Optional: focus by project/team
vercel ls <project-name> --yes

# Remove one deployment by URL or deployment id
vercel remove <deployment-id-or-url> --yes
```

## GitHub PR Branch Checks

```bash
# Find PR status for branch before deleting branch-specific preview resources
gh pr list --state all --search '<branch-name>' --json number,state,headRefName,url
```

## Reporting Template

- Scope used (project, branch matcher, age threshold)
- Resources reviewed
- Resources deleted
- Resources intentionally kept (and why)
