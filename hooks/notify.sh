#!/usr/bin/env bash
set -euo pipefail

# Determine plugin root: use CLAUDE_PLUGIN_ROOT if set, otherwise resolve from script location
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
CONFIG="${PLUGIN_ROOT}/config.json"

# Read stdin JSON
INPUT=$(cat)

# Determine event key from hook_event_name
HOOK_EVENT=$(echo "$INPUT" | /usr/bin/python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('hook_event_name',''))" 2>/dev/null || echo "")

case "$HOOK_EVENT" in
  "Notification")
    # Extract notification type from the input
    EVENT_KEY=$(echo "$INPUT" | /usr/bin/python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('notification_type', d.get('matcher', '')))" 2>/dev/null || echo "")
    ;;
  "Stop")
    EVENT_KEY="stop"
    ;;
  *)
    EVENT_KEY=""
    ;;
esac

# If no event key, output continue and exit
if [[ -z "$EVENT_KEY" ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Read config for this event key
if [[ ! -f "$CONFIG" ]]; then
  echo '{"continue": true}'
  exit 0
fi

# Parse config using Python3
CONFIG_VARS=$(
  /usr/bin/python3 - "$CONFIG" "$EVENT_KEY" <<'PYEOF'
import json, sys

config_file = sys.argv[1]
event_key = sys.argv[2]

try:
    with open(config_file) as f:
        config = json.load(f)
    c = config[event_key]
    print(f'ENABLED={str(c["enabled"]).lower()}')
    print(f'SOUND={str(c["sound"]).lower()}')
    print(f'SOUND_FILE={c["sound_file"]}')
    print(f'TITLE={c["title"]}')
    print(f'MESSAGE={c["message"]}')
except Exception:
    print('ENABLED=false')
PYEOF
) || true

# Parse the variables
ENABLED=false
SOUND=false
SOUND_FILE=""
TITLE=""
MESSAGE=""

while IFS='=' read -r key value; do
  case "$key" in
    ENABLED)    ENABLED="$value" ;;
    SOUND)      SOUND="$value" ;;
    SOUND_FILE) SOUND_FILE="$value" ;;
    TITLE)      TITLE="$value" ;;
    MESSAGE)    MESSAGE="$value" ;;
  esac
done <<< "$CONFIG_VARS"

if [[ "$ENABLED" == "true" ]]; then
  ICON="${PLUGIN_ROOT}/assets/claude.png"

  # Use alerter if available — shows Claude icon as thumbnail, works on macOS Sequoia
  if command -v alerter &>/dev/null && [[ -f "$ICON" ]]; then
    alerter --title "$TITLE" --message "$MESSAGE" --app-icon "$ICON" --timeout 5 &>/dev/null || true
  else
    # Fallback: plain osascript (no custom icon)
    /usr/bin/osascript -e "display notification \"${MESSAGE}\" with title \"${TITLE}\"" &>/dev/null || true
  fi

  # Play sound in background if enabled (afplay supports full file paths)
  if [[ "$SOUND" == "true" && -f "$SOUND_FILE" ]]; then
    /usr/bin/afplay "$SOUND_FILE" &
  fi
fi

echo '{"continue": true}'
