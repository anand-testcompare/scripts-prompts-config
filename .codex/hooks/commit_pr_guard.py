#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys


YES_PATTERNS = [
    r"\byes\b",
    r"\byep\b",
    r"\byeah\b",
    r"\bsure\b",
    r"\bok(?:ay)?\b",
    r"\bgo ahead\b",
    r"\bdo it\b",
    r"\bplease do\b",
    r"\bcommit\b",
    r"\bpr\b",
    r"\bship it\b",
]

NO_PATTERNS = [
    r"\bno\b",
    r"\bnope\b",
    r"\bnot now\b",
    r"\bdon't\b",
    r"\bdo not\b",
    r"\bskip\b",
    r"\bleave it\b",
    r"\bleave them\b",
    r"\bdon't commit\b",
    r"\bdo not commit\b",
    r"\bdon't pr\b",
    r"\bdo not pr\b",
]


def run_git(*args: str, cwd: str) -> str:
    return subprocess.check_output(
        ["git", *args],
        cwd=cwd,
        stderr=subprocess.DEVNULL,
        text=True,
    )


def git_root(cwd: str) -> str | None:
    try:
        return run_git("rev-parse", "--show-toplevel", cwd=cwd).strip()
    except subprocess.CalledProcessError:
        return None


def dirty_lines(cwd: str) -> list[str]:
    output = run_git("status", "--porcelain=v1", cwd=cwd)
    return [line for line in output.splitlines() if line]


def branch_status(cwd: str) -> tuple[int, int]:
    try:
        line = run_git("status", "--porcelain=v1", "--branch", cwd=cwd).splitlines()[0]
    except (IndexError, subprocess.CalledProcessError):
        return (0, 0)

    ahead_match = re.search(r"ahead (\d+)", line)
    behind_match = re.search(r"behind (\d+)", line)
    ahead = int(ahead_match.group(1)) if ahead_match else 0
    behind = int(behind_match.group(1)) if behind_match else 0
    return (ahead, behind)


def dirty_summary(lines: list[str], cwd: str) -> str:
    staged = 0
    unstaged = 0
    untracked = 0

    for line in lines:
        x = line[0]
        y = line[1]
        if x == "?" and y == "?":
            untracked += 1
            continue
        if x != " ":
            staged += 1
        if y != " ":
            unstaged += 1

    ahead, behind = branch_status(cwd)
    return (
        f"{staged} staged, {unstaged} unstaged, {untracked} untracked, "
        f"{ahead} ahead, {behind} behind"
    )


def signature(lines: list[str]) -> str:
    joined = "\n".join(lines)
    return hashlib.sha256(joined.encode("utf-8")).hexdigest()


def state_file_for(root: str) -> Path:
    repo_key = hashlib.sha256(root.encode("utf-8")).hexdigest()[:16]
    state_dir = Path.home() / ".codex" / ".tmp" / "commit-pr-guard"
    state_dir.mkdir(parents=True, exist_ok=True)
    return state_dir / f"{repo_key}.json"


def load_state(path: Path) -> dict[str, str]:
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        return {}
    except json.JSONDecodeError:
        return {}


def save_state(path: Path, state: dict[str, str]) -> None:
    path.write_text(json.dumps(state, sort_keys=True))


def clear_state(path: Path) -> None:
    try:
        path.unlink()
    except FileNotFoundError:
        pass


def classify_prompt(prompt: str) -> str | None:
    text = prompt.strip().lower()
    if not text:
        return None

    for pattern in NO_PATTERNS:
        if re.search(pattern, text):
            return "declined"

    for pattern in YES_PATTERNS:
        if re.search(pattern, text):
            return "approved"

    return None


def stop_message(summary: str) -> str:
    return (
        "This repository still has uncommitted changes "
        f"({summary}). Before you finish, ask the user whether they want you to "
        "commit these changes and open a PR. If they say yes, do the full git/PR "
        "cleanup yourself: sync with the latest main before committing if needed, "
        "commit, push, open a PR, monitor auto-merge, then switch back to main, "
        "pull, and confirm the merge landed. If they say no, acknowledge it and "
        "finish without asking again unless the git dirty state changes."
    )


def approved_stop_message(summary: str) -> str:
    return (
        "The user already approved commit/PR cleanup for this dirty workspace "
        f"({summary}). Do not finish yet. Complete the git/PR flow now: sync "
        "with the latest main before committing if needed, merge or rebase main "
        "if the branch drifted, commit, push, open or update the PR, monitor "
        "auto-merge, then switch back to main, pull, and confirm the merge "
        "landed."
    )


APPROVED_CONTEXT = (
    "The user approved commit/PR cleanup for the current dirty workspace. "
    "Handle the full git/PR flow before finishing: sync with latest main if "
    "needed, commit, push, open a PR, monitor auto-merge, switch back to main, "
    "pull, and confirm the merge landed."
)


DECLINED_CONTEXT = (
    "The user declined commit/PR cleanup for the current dirty workspace. "
    "Finish without asking again unless the git dirty state changes."
)


def handle_stop(payload: dict[str, object], cwd: str, state_path: Path) -> int:
    root = git_root(cwd)
    if root is None:
        return 0

    lines = dirty_lines(root)
    if not lines:
        clear_state(state_path)
        return 0

    if payload.get("stop_hook_active") is True:
        return 0

    state = load_state(state_path)
    current_signature = signature(lines)

    if state.get("decision") == "approved":
        print(approved_stop_message(dirty_summary(lines, root)), file=sys.stderr)
        return 2

    if (
        state.get("decision") == "declined"
        and state.get("signature") == current_signature
    ):
        return 0

    next_state = {
        "decision": "awaiting_user",
        "signature": current_signature,
    }
    save_state(state_path, next_state)
    print(stop_message(dirty_summary(lines, root)), file=sys.stderr)
    return 2


def handle_user_prompt_submit(payload: dict[str, object], cwd: str, state_path: Path) -> int:
    root = git_root(cwd)
    if root is None:
        return 0

    lines = dirty_lines(root)
    if not lines:
        clear_state(state_path)
        return 0

    state = load_state(state_path)
    current_signature = signature(lines)

    if state.get("decision") != "awaiting_user":
        return 0

    if state.get("signature") != current_signature:
        return 0

    decision = classify_prompt(str(payload.get("prompt") or ""))
    if decision == "approved":
        save_state(
            state_path,
            {
                "decision": "approved",
                "signature": current_signature,
            },
        )
        print(APPROVED_CONTEXT)
    elif decision == "declined":
        save_state(
            state_path,
            {
                "decision": "declined",
                "signature": current_signature,
            },
        )
        print(DECLINED_CONTEXT)

    return 0


def main() -> int:
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except json.JSONDecodeError:
        return 0

    cwd = str(payload.get("cwd") or os.getcwd())
    root = git_root(cwd)
    if root is None:
        return 0

    state_path = state_file_for(root)
    event_name = payload.get("hook_event_name")

    if event_name == "Stop":
        return handle_stop(payload, cwd, state_path)
    if event_name == "UserPromptSubmit":
        return handle_user_prompt_submit(payload, cwd, state_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
