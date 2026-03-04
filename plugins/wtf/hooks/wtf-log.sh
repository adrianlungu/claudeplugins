#!/usr/bin/env bash
# Usage: wtf-log.sh "reason" "file:line" "heuristic|judgment"
set -euo pipefail

REASON="${1:-Unknown}"
LOCATION="${2:-unknown}"
TYPE="${3:-judgment}"
WTF_FILE="${TMPDIR:-/tmp}/wtf-session.json"

if [[ ! -f "$WTF_FILE" ]]; then
  echo "wtf: session file not found at $WTF_FILE — was the plugin loaded?" >&2
  exit 1
fi

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
