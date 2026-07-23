# Pi subagents

This installs the `subagents` extension and matching skill from Ben Davis's
[`davis7dotsh/my-pi-setup`](https://github.com/davis7dotsh/my-pi-setup). It adds
Pi, Claude Code, and Codex child-agent harnesses without adopting the rest of
Ben's opinionated Pi theme, Firecrawl, terminal, or workflow configuration.

## Install

```bash
./universal/pi-subagents/install.sh
```

The installer pins the reviewed upstream commit, clones it under
`~/.local/share/pi-packages/`, installs the extension's production dependencies,
and links only these resources into `~/.pi/agent/`:

- `extensions/subagents`
- `skills/subagents`

Existing resources at either destination are timestamp-backed up before they
are replaced. Restart Pi or run `/reload` after installation.

## Security model

These are autonomous coding agents. The upstream extension launches Claude Code
with permission prompts bypassed and Codex with `approvalPolicy: never` plus
`danger-full-access`. Pi children receive the normal tool set except recursive
subagent/workflow tools. Only spawn children in repositories where autonomous
file and command access is appropriate.

## Updating

Review upstream changes, update `UPSTREAM_COMMIT` in `install.sh`, then rerun the
installer. The managed checkout refuses to overwrite tracked local changes.
