#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
LIB="${PLUGIN_ROOT}/hooks/lib"
CONFIG="${PLUGIN_ROOT}/config.json"

INPUT=$(cat)

# Source shared logic
# shellcheck source=lib/common.sh
source "${LIB}/common.sh"

# Detect platform and source the right module
case "$(uname -s)" in
  Darwin)
    PLATFORM="macos"
    # shellcheck source=lib/notify-macos.sh
    source "${LIB}/notify-macos.sh"
    ;;
  Linux)
    PLATFORM="linux"
    # shellcheck source=lib/notify-linux.sh
    source "${LIB}/notify-linux.sh"
    ;;
  *)
    echo '{"continue": true}'
    exit 0
    ;;
esac

ICON="${PLUGIN_ROOT}/assets/claude.png"

parse_event "$INPUT" "$CONFIG" "$PLATFORM"

if [[ "$ENABLED" == "true" ]]; then
  send_notification "$TITLE" "$MESSAGE" "$ICON" "$CLICK_TO_FOCUS"
  if [[ "$SOUND" == "true" ]]; then
    play_sound "$SOUND_FILE"
  fi
fi

echo '{"continue": true}'
