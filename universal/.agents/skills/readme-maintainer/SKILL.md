---
name: readme-maintainer
description: Create or update repository README.md files with concise, human-skimmable structure and verified metadata. Use when writing or refreshing README content, adding or correcting badges, documenting stack and deployment/services, and explicitly reporting testing coverage (unit, integration, e2e api, e2e web) plus CI execution status.
---

# README Maintainer

## Goal
Produce README files that are fast to skim, technically accurate, and explicit about quality signals. Prefer omission over guessing.

## Workflow
1. Collect evidence-backed facts.
2. Verify anything unclear before writing badges or version numbers.
3. Draft or update README with a compact section order.
4. Surface test layers and CI status immediately.
5. Run a final accuracy pass.

### 1) Collect Facts
Run the bundled scanner first:

```bash
python ~/.codex/skills/readme-maintainer/scripts/readme_facts.py --repo . --format markdown > /tmp/readme-facts.md
python ~/.codex/skills/readme-maintainer/scripts/readme_facts.py --repo . --format json > /tmp/readme-facts.json
```

Use `/tmp/readme-facts.json` as the source of truth for detected runtime, tools, deployment, external services, API surface, and test/CI gaps.

### 2) Verify Badge Inputs
For every versioned badge, confirm:
- Exact source file is known.
- Version precision is `exact` or clearly range-based.
- Badge value matches the repo state now.

If exact version is unknown, do not invent a number. Use an unversioned badge or omit it.

### 3) Use a Compact README Shape
Keep the document short and stable. Default order:
1. Title + one-line summary.
2. Badge block (grouped).
3. What it does (3-7 bullets).
4. How it works (short architecture summary).
5. Quick start.
6. Testing and CI matrix.
7. Deployment and external services.
8. Copyright and license.

If the project has callable APIs, include a short API section and always include an `e2e api` line in the testing matrix.

### 4) Testing and CI Must Be Up Front
Use this table near the top half of README:

| Layer | Present | Tooling | Runs in CI |
|---|---|---|---|
| unit | yes/no | tool list or `none` | yes/no |
| integration | yes/no | tool list or `none` | yes/no |
| e2e api | yes/no | tool list or `none` | yes/no |
| e2e web | yes/no | tool list or `none` | yes/no |

Rules:
- Show all four rows every time.
- Keep `no` visible; do not hide missing layers.
- If APIs are exposed and `e2e api` is missing, call it out in plain text immediately below the table.

### 5) Badge Rules
- Group badges by purpose, not alphabetically: stack, tooling, testing/ci, deploy/license.
- Keep badge count practical; drop low-value badges.
- Prefer official docs links for each badge target.
- Include license badge only when a license file or explicit license metadata exists.

Use `references/readme-patterns.md` for compact badge grouping and section templates.

### 6) Final Quality Gate
Before finalizing README changes:
- Re-run `readme_facts.py` if code changed during editing.
- Confirm every numeric badge value is source-backed.
- Call out missing tests/CI explicitly.
- Include copyright and license lines when available.
- Keep prose skimmable: short paragraphs, bullets, and tables.
