#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
SCRATCHPAD="$PROJECT_DIR/.claude/wisdom-scratchpad.md"
COUNTER_FILE="$PROJECT_DIR/.claude/.wisdom-action-count"

# Ensure .claude directory exists
mkdir -p "$PROJECT_DIR/.claude"

# Initialize scratchpad if missing
if [ ! -f "$SCRATCHPAD" ]; then
  cat > "$SCRATCHPAD" << 'EOF'
# Wisdom Scratchpad

## Principles
<!-- Max 20. Each is one sentence, specific to THIS project. -->
<!-- Format: - [evidence_count] Principle text -->

## Predictions
<!-- Last 5 predictions and outcomes. -->
<!-- Format: - [turn_N] PREDICTION: ... | OUTCOME: correct/wrong/partial | WHY: ... -->

## Stats
- Session actions: 0
- Correct predictions: 0
- Wrong predictions: 0
- Partial predictions: 0
- Error trend: stable
EOF
fi

# Read and increment counter
COUNT=0
if [ -f "$COUNTER_FILE" ]; then
  COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
fi
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# Every 5 actions, output a reminder to trigger slow module
if [ $((COUNT % 5)) -eq 0 ]; then
  cat << ENDJSON
{
  "additionalContext": "SLOW MODULE TRIGGER: You have completed $COUNT actions this session. Pause and review your last 5 predictions in .claude/wisdom-scratchpad.md. Look for patterns, update principles, and check your error trend before continuing."
}
ENDJSON
fi

exit 0
