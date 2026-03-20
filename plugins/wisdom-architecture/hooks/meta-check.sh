#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
SCRATCHPAD="$PROJECT_DIR/.claude/wisdom-scratchpad.md"

# No scratchpad yet = no principles to check against, skip
if [ ! -f "$SCRATCHPAD" ]; then
  exit 0
fi

# Check if there are any principles (non-empty principles section)
PRINCIPLES=$(sed -n '/^## Principles/,/^## /p' "$SCRATCHPAD" | grep -c '^\- \[' 2>/dev/null || echo "0")

# Check if recent accuracy is bad (3+ wrong in last 5)
WRONG=$(grep -c 'OUTCOME: wrong' "$SCRATCHPAD" 2>/dev/null || echo "0")

if [ "$PRINCIPLES" -gt 0 ] || [ "$WRONG" -ge 3 ]; then
  cat << ENDJSON
{
  "additionalContext": "META CHECK: A new file was just created. Review it against your principles in .claude/wisdom-scratchpad.md. If any principle conflicts with what you wrote, fix it now. If 3+ of your last 5 predictions were wrong, double-check the approach before continuing."
}
ENDJSON
fi

exit 0
