#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
SCRATCHPAD="$PROJECT_DIR/.claude/wisdom-scratchpad.md"

# No scratchpad = nothing to reflect on
if [ ! -f "$SCRATCHPAD" ]; then
  exit 0
fi

cat << 'ENDJSON'
{
  "additionalContext": "SLOW MODULE — SESSION END: Review .claude/wisdom-scratchpad.md. Look at the last 5 predictions. Extract or update any principles. Update the error trend. Write the updated scratchpad to disk."
}
ENDJSON

exit 0
