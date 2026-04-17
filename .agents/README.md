# Repo-Backed Agent Skills

Use `./.agents/skills` as the source of truth for skills that should be installable from this repository.

## Available Skills

- `acpx`
- `workos-agent-access`

## Install From This Repo

List installable skills:

```bash
npx skills add anand-testcompare/scripts-prompts-config -l
```

Install `acpx` globally for Codex:

```bash
npx skills add anand-testcompare/scripts-prompts-config \
  --skill acpx \
  --agent codex \
  -g -y
```

Install `workos-agent-access` globally for Codex:

```bash
npx skills add anand-testcompare/scripts-prompts-config \
  --skill workos-agent-access \
  --agent codex \
  -g -y
```

## Link From A Local Clone

If you want `~/.agents/skills/<name>` to point at this checkout directly, use:

```bash
./.agents/scripts/link-skill.sh acpx
```

Link every repo-backed skill:

```bash
./.agents/scripts/link-skill.sh --all
```

The linker targets `~/.agents/skills`, which Codex already reads on this machine.
