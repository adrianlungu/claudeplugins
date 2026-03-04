#!/usr/bin/env bash
# Usage: wtf-start-task.sh "Task description"
set -euo pipefail

DESCRIPTION="${1:-Unknown task}"
WTF_FILE="${TMPDIR:-/tmp}/wtf-session.json"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [[ ! -f "$WTF_FILE" ]]; then
  echo "wtf: session file not found at $WTF_FILE — was the plugin loaded?" >&2
  exit 1
fi

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
