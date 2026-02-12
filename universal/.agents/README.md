# Universal Agent Skills

## Local Created/Customized Skills (Copied Here)

These are maintained in this folder under `skills/`:

- `issue-grooming`
- `readme-maintainer`

## Upstream Skills (Install Instead of Copying)

These are tracked as upstream installs from `~/.agents/.skill-lock.json` and should be installed via `npx skills add`.

1. `agent-browser`

```bash
npx skills add vercel-labs/agent-browser --skill agent-browser -g -y
```

2. `code-review`

```bash
npx skills add coderabbitai/skills --skill code-review -g -y
```

3. `find-skills`

```bash
npx skills add vercel-labs/skills --skill find-skills -g -y
```

4. `pretty-mermaid`

```bash
npx skills add imxv/pretty-mermaid-skills -g -y
```

## Source Of Truth

- Local skill source: `~/.agents/skills`
- Upstream lock metadata: `~/.agents/.skill-lock.json`

## Repo Hygiene

- Ignore macOS Finder artifacts like `.DS_Store` (covered via repo `.gitignore`).
