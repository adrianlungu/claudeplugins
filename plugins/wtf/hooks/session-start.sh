#!/usr/bin/env bash
# SessionStart hook — initializes WTF temp file and injects tracking instructions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WTF_FILE="${TMPDIR:-/tmp}/wtf-session.json"
SESSION_STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SESSION_ID="$(python3 -c 'import uuid; print(str(uuid.uuid4())[:8])')"

# Ensure the temp directory exists
mkdir -p "$(dirname "$WTF_FILE")"

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
