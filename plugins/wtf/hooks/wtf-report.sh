#!/usr/bin/env bash
# Prints WTF report for current task and archives it to completed_tasks
set -euo pipefail

WTF_FILE="${TMPDIR:-/tmp}/wtf-session.json"

if [[ ! -f "$WTF_FILE" ]]; then
  echo "wtf: session file not found at $WTF_FILE — was the plugin loaded?" >&2
  exit 1
fi

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
