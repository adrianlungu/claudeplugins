# WTF Plugin Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Claude Code plugin that tracks WTF moments during Claude's work and prints a rated report at task completion.

**Architecture:** A `SessionStart` hook injects tracking instructions into Claude's context at every session start. Three helper shell scripts handle state mutations (start task, log WTF, print report) against a JSON temp file. Claude calls these scripts via Bash tool during normal work.

**Tech Stack:** Bash, Python 3 (stdlib only, for JSON manipulation), Claude Code plugin system

---

## File Map

```
wtf/
├── .claude-plugin/
│   └── plugin.json
├── hooks/
│   ├── hooks.json
│   ├── session-start.sh      ← init temp file + inject instructions
│   ├── wtf-start-task.sh     ← called when Claude begins a task
│   ├── wtf-log.sh            ← called when Claude spots a WTF
│   └── wtf-report.sh         ← called when Claude finishes a task
└── README.md
```

---

### Task 1: Plugin metadata

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `hooks/hooks.json`

**Step 1: Create plugin.json**

```json
{
  "name": "wtf",
  "description": "Tracks WTF moments during Claude's work and reports them with a rating at task completion",
  "version": "1.0.0",
  "author": {
    "name": "Adrian Lungu"
  },
  "license": "MIT",
  "keywords": ["wtf", "code-quality", "tracking", "metrics"]
}
```

**Step 2: Create hooks/hooks.json**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh",
            "async": false
          }
        ]
      }
    ]
  }
}
```

**Step 3: Commit**

```bash
git add .claude-plugin/plugin.json hooks/hooks.json
git commit -m "feat: add plugin metadata and hooks config"
```

---

### Task 2: wtf-start-task.sh

Records the start of a new task in the temp file. Called by Claude before beginning work.

**Files:**
- Create: `hooks/wtf-start-task.sh`

**Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Usage: wtf-start-task.sh "Task description"
set -euo pipefail

DESCRIPTION="${1:-Unknown task}"
WTF_FILE="${TMPDIR:-/tmp}/wtf-session.json"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

python3 - "$WTF_FILE" "$DESCRIPTION" "$STARTED_AT" << 'PYTHON'
import json, sys

wtf_file, description, started_at = sys.argv[1], sys.argv[2], sys.argv[3]

with open(wtf_file) as f:
    data = json.load(f)

data['current_task'] = {
    'description': description,
    'started_at': started_at,
    'wtfs': []
}

with open(wtf_file, 'w') as f:
    json.dump(data, f, indent=2)
PYTHON
```

**Step 2: Make executable**

```bash
chmod +x hooks/wtf-start-task.sh
```

**Step 3: Verify it works against a seed file**

```bash
# Create a minimal seed file
echo '{"session_id":"test","session_started_at":"2026-02-20T00:00:00Z","session_total":0,"current_task":null,"completed_tasks":[]}' \
  > "${TMPDIR:-/tmp}/wtf-session.json"

hooks/wtf-start-task.sh "Refactor auth module"

python3 -c "
import json
with open('${TMPDIR:-/tmp}/wtf-session.json') as f:
    d = json.load(f)
assert d['current_task']['description'] == 'Refactor auth module', 'task not set'
assert d['current_task']['wtfs'] == [], 'wtfs should be empty'
print('PASS')
"
```

Expected: `PASS`

**Step 4: Commit**

```bash
git add hooks/wtf-start-task.sh
git commit -m "feat: add wtf-start-task helper script"
```

---

### Task 3: wtf-log.sh

Appends a WTF entry to the current task in the temp file. Called by Claude when it spots a WTF moment.

**Files:**
- Create: `hooks/wtf-log.sh`

**Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Usage: wtf-log.sh "reason" "file:line" "heuristic|judgment"
set -euo pipefail

REASON="${1:-Unknown}"
LOCATION="${2:-unknown}"
TYPE="${3:-judgment}"
WTF_FILE="${TMPDIR:-/tmp}/wtf-session.json"

python3 - "$WTF_FILE" "$REASON" "$LOCATION" "$TYPE" << 'PYTHON'
import json, sys

wtf_file, reason, location, wtf_type = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

with open(wtf_file) as f:
    data = json.load(f)

# Create a task if none exists (safety net)
if data.get('current_task') is None:
    data['current_task'] = {
        'description': 'Unnamed task',
        'started_at': '',
        'wtfs': []
    }

data['current_task']['wtfs'].append({
    'reason': reason,
    'location': location,
    'type': wtf_type
})

with open(wtf_file, 'w') as f:
    json.dump(data, f, indent=2)
PYTHON
```

**Step 2: Make executable**

```bash
chmod +x hooks/wtf-log.sh
```

**Step 3: Verify it works**

```bash
# Seed file with an active task
echo '{"session_id":"test","session_started_at":"2026-02-20T00:00:00Z","session_total":0,"current_task":{"description":"test task","started_at":"","wtfs":[]},"completed_tasks":[]}' \
  > "${TMPDIR:-/tmp}/wtf-session.json"

hooks/wtf-log.sh "Magic number 42" "auth.js:47" "heuristic"
hooks/wtf-log.sh "Function does everything" "auth.js:100" "judgment"

python3 -c "
import json
with open('${TMPDIR:-/tmp}/wtf-session.json') as f:
    d = json.load(f)
wtfs = d['current_task']['wtfs']
assert len(wtfs) == 2, f'expected 2 wtfs, got {len(wtfs)}'
assert wtfs[0]['type'] == 'heuristic'
assert wtfs[1]['type'] == 'judgment'
print('PASS')
"
```

Expected: `PASS`

**Step 4: Commit**

```bash
git add hooks/wtf-log.sh
git commit -m "feat: add wtf-log helper script"
```

---

### Task 4: wtf-report.sh

Prints the rated WTF report for the current task, archives it to `completed_tasks`, and updates the session total.

**Files:**
- Create: `hooks/wtf-report.sh`

**Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Prints WTF report for current task and archives it to completed_tasks
set -euo pipefail

WTF_FILE="${TMPDIR:-/tmp}/wtf-session.json"

python3 - "$WTF_FILE" << 'PYTHON'
import json, sys

wtf_file = sys.argv[1]

with open(wtf_file) as f:
    data = json.load(f)

task = data.get('current_task') or {}
wtfs = task.get('wtfs', [])
count = len(wtfs)

def get_rating(n):
    if n == 0:   return '✨ Pristine'
    if n <= 2:   return '👌 Mostly clean'
    if n <= 5:   return '🤨 Some questionable choices'
    if n <= 10:  return '🔥 Cursed, but survivable'
    if n <= 20:  return '☠️ Abandon all hope'
    return '👹 Call an exorcist'

print('╔══════════════════════════════════════╗')
print('║         WTF REPORT                   ║')
print('╚══════════════════════════════════════╝')
print(f'Task: {task.get("description", "Unknown")}')
print(f'WTFs this task: {count}')
print(f'Rating: {get_rating(count)}')

if wtfs:
    print()
    for w in wtfs:
        print(f'  • [{w["type"]}] {w["reason"]} — {w["location"]}')

# Archive task and update session total
data['session_total'] = data.get('session_total', 0) + count
if 'completed_tasks' not in data:
    data['completed_tasks'] = []
if task:
    task['wtf_count'] = count
    data['completed_tasks'].append(task)
data['current_task'] = None

completed = len(data['completed_tasks'])
print()
print(f'Session total: {data["session_total"]} WTF(s) across {completed} task(s)')

with open(wtf_file, 'w') as f:
    json.dump(data, f, indent=2)
PYTHON
```

**Step 2: Make executable**

```bash
chmod +x hooks/wtf-report.sh
```

**Step 3: Verify output format and state mutation**

```bash
# Seed file with 7 WTFs
python3 -c "
import json
data = {
  'session_id': 'test',
  'session_started_at': '2026-02-20T00:00:00Z',
  'session_total': 5,
  'current_task': {
    'description': 'Refactor auth module',
    'started_at': '2026-02-20T13:00:00Z',
    'wtfs': [
      {'reason': 'Magic number 42', 'location': 'auth.js:47', 'type': 'heuristic'},
      {'reason': 'Function does everything', 'location': 'auth.js:100', 'type': 'judgment'},
      {'reason': 'Variable named data2', 'location': 'auth.js:212', 'type': 'heuristic'},
      {'reason': 'TODO from 2019', 'location': 'auth.js:300', 'type': 'heuristic'},
      {'reason': 'Hardcoded prod URL', 'location': 'auth.js:5', 'type': 'heuristic'},
      {'reason': 'Copy-paste block 40 lines', 'location': 'auth.js:400', 'type': 'heuristic'},
      {'reason': 'Auth logic inside view layer', 'location': 'auth.js:500', 'type': 'judgment'},
    ]
  },
  'completed_tasks': [{'description': 'previous', 'wtf_count': 5}]
}
with open('${TMPDIR:-/tmp}/wtf-session.json', 'w') as f:
    json.dump(data, f, indent=2)
"

hooks/wtf-report.sh

# Verify state was mutated correctly
python3 -c "
import json
with open('${TMPDIR:-/tmp}/wtf-session.json') as f:
    d = json.load(f)
assert d['current_task'] is None, 'current_task should be None after report'
assert d['session_total'] == 12, f'session total should be 12, got {d[\"session_total\"]}'
assert len(d['completed_tasks']) == 2
print('PASS')
"
```

Expected output includes `Rating: 🔥 Cursed, but survivable` and `Session total: 12 WTF(s) across 2 task(s)`, then `PASS`

**Step 4: Commit**

```bash
git add hooks/wtf-report.sh
git commit -m "feat: add wtf-report helper script with rating system"
```

---

### Task 5: session-start.sh

The main hook. Initializes the temp file and injects WTF tracking instructions into Claude's context.

**Files:**
- Create: `hooks/session-start.sh`

**Step 1: Write the script**

```bash
#!/usr/bin/env bash
# SessionStart hook — initializes WTF temp file and injects tracking instructions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WTF_FILE="${TMPDIR:-/tmp}/wtf-session.json"
SESSION_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SESSION_ID="$(python3 -c 'import uuid; print(str(uuid.uuid4())[:8])')"

# Initialize temp file
python3 - "$WTF_FILE" "$SESSION_ID" "$SESSION_STARTED_AT" << 'PYTHON'
import json, sys

data = {
    "session_id": sys.argv[2],
    "session_started_at": sys.argv[3],
    "session_total": 0,
    "current_task": None,
    "completed_tasks": []
}

with open(sys.argv[1], 'w') as f:
    json.dump(data, f, indent=2)
PYTHON

# Build instructions with actual resolved paths embedded
INSTRUCTIONS="You are now tracking WTF moments — confusing, surprising, poorly designed, or questionable things you encounter during your work.

## WTF state file
${WTF_FILE}

## When starting a task
Before beginning any significant unit of work (refactor, review, feature, bug fix), run:
\`\`\`bash
\"${PLUGIN_ROOT}/hooks/wtf-start-task.sh\" \"Brief description of the task\"
\`\`\`

## Heuristic WTF triggers — always count these
- Magic numbers or unexplained constants
- A function doing 3+ unrelated things
- Inconsistent naming within the same file
- Commented-out code blocks
- Variables named temp, data, x, foo, temp2
- TODO/FIXME/HACK comments
- Obvious copy-paste violations (DRY failures)
- Deeply nested callbacks / pyramid of doom
- Hardcoded config or credentials in source
- Missing error handling on critical paths

## Judgment-based WTF triggers — count anything that makes you think \"wait... why?\"
- Surprising architectural decisions
- Tests that test nothing meaningful
- Files over 1000 lines
- Logic that contradicts its own comments
- Anything else that genuinely confuses you

## When you encounter a WTF moment
\`\`\`bash
\"${PLUGIN_ROOT}/hooks/wtf-log.sh\" \"reason\" \"file:line\" \"heuristic\"
# or for judgment calls:
\"${PLUGIN_ROOT}/hooks/wtf-log.sh\" \"reason\" \"file:line\" \"judgment\"
\`\`\`

## When finishing a task
After completing a task, run:
\`\`\`bash
\"${PLUGIN_ROOT}/hooks/wtf-report.sh\"
\`\`\`
This prints the rated WTF report and updates the session total."

# Escape content for JSON embedding
escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

INSTRUCTIONS_ESCAPED=$(escape_for_json "$INSTRUCTIONS")

cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<wtf-tracking-instructions>\n${INSTRUCTIONS_ESCAPED}\n</wtf-tracking-instructions>"
  }
}
EOF

exit 0
```

**Step 2: Make executable**

```bash
chmod +x hooks/session-start.sh
```

**Step 3: Verify JSON output is valid**

```bash
hooks/session-start.sh | python3 -c "
import json, sys
data = json.load(sys.stdin)
assert 'hookSpecificOutput' in data
assert data['hookSpecificOutput']['hookEventName'] == 'SessionStart'
assert 'wtf-tracking-instructions' in data['hookSpecificOutput']['additionalContext']
assert 'wtf-start-task.sh' in data['hookSpecificOutput']['additionalContext']
assert 'wtf-log.sh' in data['hookSpecificOutput']['additionalContext']
assert 'wtf-report.sh' in data['hookSpecificOutput']['additionalContext']
print('PASS: JSON output is valid and contains expected instructions')
"
```

Expected: `PASS: JSON output is valid and contains expected instructions`

**Step 4: Verify temp file was created**

```bash
python3 -c "
import json
with open('${TMPDIR:-/tmp}/wtf-session.json') as f:
    d = json.load(f)
assert d['session_total'] == 0
assert d['current_task'] is None
assert d['completed_tasks'] == []
assert len(d['session_id']) == 8
print('PASS: temp file initialized correctly')
"
```

Expected: `PASS: temp file initialized correctly`

**Step 5: Commit**

```bash
git add hooks/session-start.sh
git commit -m "feat: add session-start hook with WTF tracking instruction injection"
```

---

### Task 6: README

**Files:**
- Create: `README.md`

**Step 1: Write README**

```markdown
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
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README"
```

---

### Task 7: End-to-end smoke test

Simulate a full task cycle to verify all scripts work together.

**Step 1: Run the full cycle**

```bash
# Start fresh session
hooks/session-start.sh > /dev/null

# Start a task
hooks/wtf-start-task.sh "Review payment module"

# Log some WTFs
hooks/wtf-log.sh "Magic number 9999" "payment.js:12" "heuristic"
hooks/wtf-log.sh "TODO from 2020" "payment.js:88" "heuristic"
hooks/wtf-log.sh "Entire validation in view layer" "payment.js:200" "judgment"

# Print report
hooks/wtf-report.sh
```

**Step 2: Verify output**

Expected output contains:
- `Task: Review payment module`
- `WTFs this task: 3`
- `Rating: 🤨 Some questionable choices`
- Three bullet points
- `Session total: 3 WTF(s) across 1 task(s)`

**Step 3: Start a second task, log 0 WTFs, report**

```bash
hooks/wtf-start-task.sh "Write unit tests"
hooks/wtf-report.sh
```

Expected:
- `WTFs this task: 0`
- `Rating: ✨ Pristine`
- `Session total: 3 WTF(s) across 2 task(s)`

**Step 4: Commit**

```bash
git add .
git commit -m "test: verify end-to-end task cycle works"
```
