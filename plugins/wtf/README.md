# wtf

A Claude Code plugin that tracks WTF moments during Claude's work and prints a rated report when a task completes.

## What it does

When Claude is doing a refactor, review, or any other task, it now:

1. Tracks confusing/surprising/questionable things it encounters
2. Logs each WTF with a reason, location, and type (heuristic or judgment)
3. Prints a rated report at the end of each task
4. Accumulates a session total across all tasks

## WTF triggers

**Heuristic (predefined):** magic numbers, functions doing 3+ things, inconsistent naming, commented-out code, bad variable names, TODO/FIXME/HACK comments, copy-paste violations, pyramid of doom, hardcoded config, missing error handling.

**Judgment (open-ended):** anything that makes Claude think "wait... why?"

## Report format

```
╔══════════════════════════════════════╗
║         WTF REPORT                   ║
╚══════════════════════════════════════╝
Task: Refactor auth module
WTFs this task: 7
Rating: 🔥 Cursed, but survivable

  • [heuristic] Magic number 42 — auth.js:47
  • [judgment]  Function handles login, logout AND password reset — auth.js:100

Session total: 12 WTF(s) across 2 task(s)
```

## Rating scale

| WTFs | Rating |
|------|--------|
| 0 | ✨ Pristine |
| 1–2 | 👌 Mostly clean |
| 3–5 | 🤨 Some questionable choices |
| 6–10 | 🔥 Cursed, but survivable |
| 11–20 | ☠️ Abandon all hope |
| 21+ | 👹 Call an exorcist |

## Installation

```bash
/plugin install wtf
```

## How it works

A `SessionStart` hook injects WTF tracking instructions into Claude's context at every session start. Three helper scripts (`wtf-start-task.sh`, `wtf-log.sh`, `wtf-report.sh`) handle state mutations against a JSON file in `$TMPDIR`. The temp file is reset each session.
