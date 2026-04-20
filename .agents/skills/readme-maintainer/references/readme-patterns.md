# README Patterns

Use these patterns to keep README output short and scannable.

## Badge Grouping Pattern

```md
<!-- Core Stack -->
[badge 1] [badge 2] [badge 3]

<!-- Tooling -->
[badge 4] [badge 5]

<!-- Testing & CI -->
[badge 6] [badge 7]

<!-- Deployment & License -->
[badge 8] [badge 9]
```

Prefer this order for badge content:
1. Runtime/framework versions
2. Testing tools
3. CI provider
4. Deployment target
5. License

## Testing Matrix Pattern

```md
## Testing and CI

| Layer | Present | Tooling | Runs in CI |
|---|---|---|---|
| unit | yes | pytest | yes |
| integration | yes | pytest | yes |
| e2e api | no | none | no |
| e2e web | no | none | no |
```

Keep `no` values visible. Do not delete rows.

## Concise Section Pattern

```md
## What It Does
- Bullet 1
- Bullet 2
- Bullet 3

## How It Works
One short paragraph plus a 3-6 bullet flow.

## Quick Start
Minimal install + run commands only.
```

## Copyright and License Pattern

```md
## Copyright
Copyright (c) YYYY <owner>

## License
MIT. See `LICENSE`.
```

If no license exists, state that explicitly:

```md
## License
No license file detected.
```
