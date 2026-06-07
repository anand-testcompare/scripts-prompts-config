---
name: codex-goal-prompting
description: Craft concise, outcome-driven prompts for Codex Goal/autonomous mode. Use when delegating broad product or coding goals where the agent should infer the right plan, explore, iterate, test affected real surfaces, and avoid checklist-minimum work.
---

# Codex Goal Prompting

Codex Goal prompts must fit Codex's goal objective limit: **4,000 characters max, including whitespace**. Aim for **3,500 characters or less** to leave room for command wrappers or edits. For broad work, write the full instructions to `goal.md` in the repo root unless the repo has a clearer documented convention. The short `/goal` objective must explicitly reference `goal.md`.

Within that limit, prompts should be short enough to preserve autonomy, but concrete enough to convey intent. A strong prompt is usually **2–4 compact sections**: goal, functional scope, hard boundaries, and proof. Use bullets for scope when they clarify product intent; avoid file-by-file or implementation-by-implementation checklists.

The key is to ask Codex to own the solution: investigate first, compare data to product behavior, notice oddities, iterate, clean up, and prove the outcome on the **affected real surfaces**. If testing exposes an in-scope bug, Codex should fix it and retest instead of stopping at task-shaped completion. Do not require irrelevant interfaces: use agent-browser only for web/app changes, pilotty/TUI capture only for TUI changes, API e2e only for API/contract changes, etc. Prefer real/local services without mocks or fixtures for product proof; fixtures are supporting tests, not user-visible proof.

## Default Pattern

```text
Goal: <product outcome and why it matters>. <Current failure mode/example>. Own the solution: inspect the relevant code/data/UI, decide the cleanest approach, iterate when something looks off, and do not reduce this to a checklist-shaped change.

Functional scope:
- <compact set of product capabilities/outcomes, not exact implementation steps>
- <include explicit deferrals when important>

Hard boundaries: <anti-goals/contracts>. Do not <known bad paths>.

Proof: Test the affected real surfaces end-to-end without mocks/fixtures where product behavior changed. Use <agent-browser/pilotty/API/local smoke/etc. only when relevant>. Compare stored data/API output to what users actually see, test rich and sparse cases, fix in-scope failures found during exploration, and report what changed, what evidence proves it, and what remains intentionally deferred.
```

## Goal File

For broad goals, create `goal.md` with the full context:

```text
# Goal
<outcome and why it matters>

# Scope
<functional outcomes, affected surfaces, known examples>

# Boundaries
<non-goals, contracts, out-of-scope blockers to report>

# Proof
<end-to-end checks, exploratory testing, required evidence>
```

Then use a short objective such as:

```text
/goal Follow ./goal.md. Own the outcome end to end: explore, implement, test affected real surfaces, fix in-scope failures found during verification, and stop only when the goal is proven or a real out-of-scope blocker is identified.
```

Verify the objective length, counting whitespace:

```bash
node -e 'const fs = require("fs"); const s = fs.readFileSync(process.argv[1], "utf8"); const n = [...s].length; console.log(`${n} chars`); process.exit(n <= 4000 ? 0 : 1)' goal-objective.txt
```

## Guidance

- Keep the final goal objective under 4,000 characters including whitespace; target 3,500 or less.
- Put longer instructions in `goal.md` and make the goal reference that file.
- Include functional scope when it communicates the shape of success.
- Keep scope outcome-oriented: “search detail explains created/enriched/unchanged” is good; “edit file X and add field Y” is usually bad.
- Be explicit about affected surfaces and only require verification for those surfaces.
- Require exploratory testing for non-doc implementation.
- Say to continue fixing in-scope failures found during verification.
- Say “without mocks/fixtures” for product proof when real/local services are available.
- Still allow deterministic fixture/unit tests as supporting coverage.

## Avoid

- Goal objectives over 4,000 characters.
- Long task lists that invite checklist compliance.
- Goals that allow stopping after the first plausible patch.
- File-by-file instructions unless the file is a hard contract.
- Predicting every edge case.
- Requiring pilotty for non-TUI work or agent-browser for non-web/app work.
- Letting verification mean typecheck-only.
