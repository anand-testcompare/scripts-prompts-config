---
name: issue-grooming
description: |
  Groom GitHub issues into implementation-ready specs that a human can ship without follow-up questions.
  Use when a GitHub issue is ambiguous or incomplete and needs: clear scope and non-goals, dependencies, file touchpoints,
  a step-by-step implementation strategy, a test plan (with explicit test type per scenario), and acceptance criteria.
  Also use when you need a GitHub-renderable Mermaid diagram (2+ systems/data flows) and a way to sanity-check Mermaid syntax.
---

# issue-grooming

## Overview

Produce concise, high-signal GitHub issues that define:

- What we are building/fixing and why
- What is in-scope vs out-of-scope (non-goals)
- What changes are needed (files/systems), and in what order
- How we will prove it works (test scenarios + acceptance criteria, each with an explicit test type)
- How the systems interact (Mermaid diagram when 2+ systems are involved)

## Quick Start

1. Read the issue:

   ```bash
   gh issue view N
   ```

2. Scaffold a spec body (feature/chore or bug):

   ```bash
   # Run from the skill folder (or use an absolute path to the script).
   # cd ~/.agents/skills/issue-grooming

   # feature/chore (default)
   node scripts/scaffold_issue_spec.mjs --issue N --stdout > /tmp/issue.md

   # bug
   node scripts/scaffold_issue_spec.mjs --issue N --kind bug --stdout > /tmp/issue.md
   ```

3. Fill in the placeholders, then update the issue:

   ```bash
   gh issue edit N --body-file /tmp/issue.md
   ```

## Workflow (Grooming Loop)

### 1. Gather Context (Do Not Guess)

Capture enough context that an engineer can implement without DMing you:

- Current behavior vs expected behavior (bugs)
- Source of truth: screenshots, logs, error messages, repro video, links, environment details
- Constraints: data shape, perf, security, rollout, compatibility, timebox
- Prior art: related issues/PRs, relevant docs, previous incidents

### Readability Bar (Optimized for Humans)

Keep the issue body scannable:

- Prefer short sections and bullets over long paragraphs
- Delete unused template sections (do not leave empty headings)
- Replace “TBD” with either a decision or an explicit open question
- Use concrete nouns: file paths, endpoints, function names, feature flags
- Keep acceptance criteria crisp; move nuance into “Implementation Strategy”

### 2. Define Scope and Non-Goals

Make the boundaries explicit:

- In scope: the minimal set needed to deliver user value
- Out of scope: tempting follow-ups that should be separate issues
- Assumptions: only include if validated; otherwise list as “Open Questions”

### 3. Identify Systems and Files Involved

List concrete touchpoints (examples; adjust per repo):

- Frontend: `apps/web/`
- Backend (Convex): `packages/backend/`
- Shared: `packages/*`

Prefer “touchpoints + intent” over long file lists.

### 4. Dependencies and Sequencing

Link everything:

- Blocked by: #N (why)
- Blocks: #M (why)
- Related: #X (context)

If the issue depends on a schema change or a migration, call it out explicitly.

### 5. Write an Implementation Strategy (Executable Steps)

Aim for a small set of ordered steps. Each step should have:

- Goal
- Key edits (files/modules)
- Notes on edge cases
- Rollback/mitigation if the step is risky

### 6. Tests: Classify Every Scenario

Do not leave “tests TBD”. Every acceptance criterion must have a test type:

- `convex`: backend logic (queries/mutations/actions)
- `stagehand`: E2E browser flows
- `stagehand+visual`: E2E plus visual/LLM grading
- `venom`: public API contracts (use when applicable)
- `manual`: checklist-style verification steps (include the checklist)
- `no test`: allowed only with a specific reason

Use `assets/test-scenarios-template.md` and `assets/acceptance-criteria-template.md` to keep the issue readable.

### 7. Mermaid: Required for 2+ Systems/Data Flows

Add a Mermaid diagram when:

- A request crosses boundaries (web <-> backend, backend <-> external services)
- There is non-trivial data flow, async job flow, or authorization flow

Keep diagrams small and label edges with verbs.

Before shipping, sanity-check GitHub rendering:

- Confirm GitHub’s Mermaid version by pasting this into a comment (or a scratch issue):
  ```mermaid
  info
  ```
- Validate locally when you can (see `references/github-mermaid.md` and `scripts/validate_mermaid_in_md.mjs`).

## Templates (Copy/Paste)

Use these as the starting point for the issue body:

- Feature/chore issue body: `assets/issue-body-template.md`
- Bug issue body: `assets/issue-body-template-bug.md`
- Acceptance criteria blocks: `assets/acceptance-criteria-template.md`
- Test scenarios checklist: `assets/test-scenarios-template.md`

## Commands (GitHub CLI)

```bash
gh issue list
gh issue view N
gh issue edit N --add-label X
gh issue edit N --body-file /path/to/body.md
```

## Mermaid for GitHub (Rules of Thumb)

See `references/github-mermaid.md` for details and a “common failures” section. Highlights:

- Use fenced blocks exactly: triple backticks + `mermaid`
- Avoid advanced Mermaid features unless you have confirmed GitHub’s Mermaid version via `info`
- Keep node IDs simple (`A`, `auth_service`) and put human labels in brackets/quotes
- If a diagram renders locally but not on GitHub, simplify first (remove init directives/theme config, complex labels, HTML)

## Included Scripts

- `scripts/scaffold_issue_spec.mjs`: generate a ready-to-fill issue body from the templates (optionally pulls title/URL via `gh`)
- `scripts/validate_mermaid_in_md.mjs`: extract Mermaid code blocks from a Markdown file and render them via Mermaid CLI to catch syntax errors early
