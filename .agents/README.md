# Repo-Backed Agent Skills

Use `./.agents/skills` as the git-tracked source of truth for skills that should be installable from this repository.

Installed copies belong in `~/.agents/skills`. That shared location is picked up by Codex, OpenCode, Pi, and the other tools that read the universal `.agents` skill directory.

Do not symlink repo skills into `~/.agents/skills`. Install them with `npx skills add` so every machine follows the same path.

## Available Skills

- `acpx`
- `workos-agent-access`

## Install From This Repo

List installable skills:

```bash
npx skills add anand-testcompare/scripts-prompts-config -l
```

Install `acpx` into `~/.agents/skills`:

```bash
npx skills add anand-testcompare/scripts-prompts-config \
  --skill acpx \
  -g -y
```

Interactive install:

```bash
npx skills add anand-testcompare/scripts-prompts-config
```

Install `workos-agent-access` into `~/.agents/skills`:

```bash
npx skills add anand-testcompare/scripts-prompts-config \
  --skill workos-agent-access \
  -g -y
```
