---
name: codex-goal-prompting
description: Craft concise, outcome-driven prompts for Codex Goal/autonomous mode. Use when delegating broad product or coding goals where the agent should infer the right plan, explore, iterate, test affected real surfaces, and avoid checklist-minimum work.
---

# Codex Goal Prompting

Codex Goal prompts should be short enough to preserve autonomy, but concrete enough to convey intent. A strong prompt is usually **2–4 compact sections**: goal, functional scope, hard boundaries, and proof. Use bullets for scope when they clarify product intent; avoid file-by-file or implementation-by-implementation checklists.

The key is to ask Codex to own the solution: investigate first, compare data to product behavior, notice oddities, iterate, clean up, and prove the outcome on the **affected real surfaces**. Do not require irrelevant interfaces: use agent-browser only for web/app changes, pilotty/TUI capture only for TUI changes, API e2e only for API/contract changes, etc. Prefer real/local services without mocks or fixtures for product proof; fixtures are supporting tests, not user-visible proof.

## Default Pattern

```text
Goal: <product outcome and why it matters>. <Current failure mode/example>. Own the solution: inspect the relevant code/data/UI, decide the cleanest approach, iterate when something looks off, and do not reduce this to a checklist-shaped change.

Functional scope:
- <small set of product capabilities/outcomes, not exact implementation steps>
- <include explicit deferrals when important>

Hard boundaries: <anti-goals/contracts>. Do not <known bad paths>.

Proof: Test the affected real surfaces end-to-end without mocks/fixtures where product behavior changed. Use <agent-browser/pilotty/API/local smoke/etc. only when relevant>. Compare stored data/API output to what users actually see, test rich and sparse cases, and report what changed, what evidence proves it, and what remains intentionally deferred.
```

## Guidance

- Include functional scope when it communicates the shape of success.
- Keep scope outcome-oriented: “search detail explains created/enriched/unchanged” is good; “edit file X and add field Y” is usually bad.
- Be explicit about affected surfaces and only require verification for those surfaces.
- Say “without mocks/fixtures” for product proof when real/local services are available.
- Still allow deterministic fixture/unit tests as supporting coverage.

## Avoid

- Long task lists that invite checklist compliance.
- File-by-file instructions unless the file is a hard contract.
- Predicting every edge case.
- Requiring pilotty for non-TUI work or agent-browser for non-web/app work.
- Letting verification mean typecheck-only.
