# WTF Plugin Design

**Date:** 2026-02-20
**Status:** Approved

## Overview

A Claude Code plugin that tracks "WTF moments" during Claude's work — confusing code, surprising architecture, questionable decisions — and reports them with a rating at the end of each task.

## Goals

- Automatically track WTF moments during any task (refactor, review, feature work, etc.)
- Report per-task count + rated summary when a task completes
- Accumulate session total across all tasks in a session
- No user interaction required — always on

## Plugin Structure

```
wtf/
├── .claude-plugin/
│   └── plugin.json
├── hooks/
│   ├── hooks.json
│   └── session-start.sh
└── README.md
```

## Mechanism

### SessionStart Hook

`session-start.sh` runs at every session start/resume. It:

1. Initializes `$TMPDIR/wtf-session.json` with a fresh session ID and empty state
2. Injects `<wtf-tracking-instructions>` into Claude's context via `hookSpecificOutput.additionalContext`

No `PostToolUse` hook, no live display — the report prints only when a task finishes.

## Temp File Schema

Location: `$TMPDIR/wtf-session.json`

```json
{
  "session_id": "abc123",
  "session_started_at": "2026-02-20T13:00:00Z",
  "session_total": 0,
  "current_task": {
    "description": "Refactor auth module",
    "started_at": "2026-02-20T13:01:00Z",
    "wtfs": [
      {
        "reason": "Magic number 42 with no comment",
        "location": "auth.js:47",
        "type": "heuristic"
      }
    ]
  },
  "completed_tasks": []
}
```

## Instructions Injected into Claude's Context

Claude is instructed to:

1. **When starting a task** — write a `current_task` entry to the temp file via Bash
2. **During work** — whenever it encounters a WTF moment, append an entry to `current_task.wtfs` via Bash
3. **When finishing a task** — read the file, print the rated report, move `current_task` into `completed_tasks`, update `session_total`

## WTF Triggers

### Heuristic (predefined patterns)
- Magic numbers / unexplained constants
- Function doing 3+ unrelated things
- Inconsistent naming within the same file
- Commented-out code blocks
- Variables named `temp`, `data`, `x`, `foo`, `temp2`
- TODO/FIXME/HACK comments
- Obvious DRY violations (copy-paste code)
- Deeply nested callbacks / pyramid of doom
- Hardcoded config/credentials in source code
- Missing error handling on critical paths

### Judgment-based (open-ended)
Anything that makes Claude pause and think "wait… why?" — surprising architecture decisions, tests that test nothing, files >1000 lines, logic that contradicts its own comments, etc.

## End-of-Task Report Format

```
╔══════════════════════════════════════╗
║         WTF REPORT                   ║
╚══════════════════════════════════════╝
Task: Refactor auth module
WTFs this task: 7
Rating: 🔥 Cursed, but survivable

• [heuristic] Magic number 42 — auth.js:47
• [judgment]  Function handles login, logout AND password reset — auth.js:100
• [heuristic] Variable named "data2" — auth.js:212

Session total: 12 WTFs across 2 tasks
```

## Rating Scale

| WTFs | Rating |
|------|--------|
| 0 | ✨ Pristine |
| 1–2 | 👌 Mostly clean |
| 3–5 | 🤨 Some questionable choices |
| 6–10 | 🔥 Cursed, but survivable |
| 11–20 | ☠️ Abandon all hope |
| 21+ | 👹 Call an exorcist |

## Decisions Made

- **Approach A** (SessionStart hook injection) chosen over Skill-based or hook+hook approaches — most seamless, always on
- **Temp file** chosen for state storage so the count survives context compression
- **Both heuristic and judgment-based** triggers — predefined patterns as anchors, Claude's judgment for anything else
- **Per-task + session total** tracking
- **No live display** — report only prints at end of task to avoid noise
