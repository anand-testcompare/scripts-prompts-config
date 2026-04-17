# Universal Agent Skills

This folder backs up portable home-directory agent config and skill content.
If you want a skill to be installable from this repository via `npx skills add ...`,
track it under repo-root `./.agents/skills` instead and install it into `~/.agents/skills`.
See [../../.agents/README.md](../../.agents/README.md).

## Local Created/Customized Skills (Copied Here)

These are maintained in this folder under `skills/`:

- `convex-delete-deployments`
- `issue-grooming`
- `preview-cleanup`
- `readme-maintainer`
- `workos-convex-authkit`

## Install From This Repo

Use this repository as the source for shared custom skills:

```bash
# List available skills
npx skills add anand-testcompare/scripts-prompts-config -l

# Install one skill globally for Codex
npx skills add anand-testcompare/scripts-prompts-config \
  --skill convex-delete-deployments \
  --agent codex \
  -g -y

# Install all skills from this repo globally
npx skills add anand-testcompare/scripts-prompts-config --all -g
```

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
