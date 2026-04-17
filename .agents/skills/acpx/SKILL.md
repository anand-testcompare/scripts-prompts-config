---
name: acpx
description: Use acpx for persistent ACP coding-agent sessions. Prefer sessions ensure + prompt -f + polling. Avoid exec unless a true one-shot is explicitly requested.
---

# acpx

## Use this when

Use `acpx` when you need to:
- launch or reuse a coding-agent session
- send a substantial prompt from a file
- queue follow-up work on the same session
- poll an agent until the delegated slice is actually done

## Default operating style

Unless the user explicitly asks for a one-shot run:
- use persistent sessions
- use `sessions ensure`
- use named sessions with `-s/--session`
- use `prompt -f <file>`
- poll until completion
- do not default to `exec`

## Preferred commands

### Codex

```bash
acpx --approve-all --auth-policy fail codex sessions ensure --name <session>
acpx --approve-all --auth-policy fail codex set thought_level high -s <session>
acpx --approve-all --auth-policy fail codex set model gpt-5.4 -s <session>
acpx --approve-all --auth-policy fail codex prompt -s <session> -f <prompt-file>
```

### Claude

```bash
acpx --approve-all --auth-policy fail claude sessions ensure --name <session>
acpx --approve-all --auth-policy fail claude prompt -s <session> -f <prompt-file>
```

Claude preference:
- use the user's configured default/profile for **Opus 4.7 xhigh**
- do not guess a Claude model id unless the user explicitly asks or the exact id is known

## Useful follow-ups

### Queue behind active work

```bash
acpx codex prompt -s <session> --no-wait -f <prompt-file>
```

### Inspect live state

```bash
acpx codex status -s <session>
acpx codex sessions show <session>
acpx codex sessions history <session> --limit 20
```

Use the same shape for Claude by replacing `codex` with `claude`.

### Cancel active turn

```bash
acpx codex cancel -s <session>
acpx claude cancel -s <session>
```

### Hard reset a session

```bash
acpx codex sessions close <session>
acpx codex sessions ensure --name <session>
```

## Polling rule

Unless otherwise requested, poll the delegated session until it is actually done.

Example:

```bash
python3 - <<'PY'
import subprocess, time
agent = "codex"
session = "backend"
for i in range(30):
    print(f"== poll {i+1} ==")
    subprocess.run(["acpx", agent, "status", "-s", session], check=False)
    subprocess.run(["acpx", agent, "sessions", "history", session, "--limit", "10"], check=False)
    subprocess.run(["git", "status", "--short"], check=False)
    time.sleep(10)
PY
```

Adjust `agent` and `session` as needed.

## Output modes worth using

```bash
acpx --format text codex prompt -s <session> -f <prompt-file>
acpx --format json codex prompt -s <session> -f <prompt-file>
acpx --format json --json-strict codex prompt -s <session> -f <prompt-file>
```

Use `--suppress-reads` when read-file output would be noisy.

## `exec`

Use `exec` only for a real one-shot with no desired session reuse or polling.

```bash
acpx --format quiet codex exec "summarize this repo in 3 lines"
```
