#!/usr/bin/env bash
# Shared: event parsing, config reading, rich message building

# parse_event <json_input> <config_file> <platform>
# Sets exported variables: ENABLED, TITLE, MESSAGE, SOUND, SOUND_FILE, CLICK_TO_FOCUS, ICON
parse_event() {
  local input="$1"
  local config_file="$2"
  local platform="$3"  # "macos" or "linux"

  local result
  result=$(
    HOOK_INPUT="$input" /usr/bin/python3 - "$config_file" "$platform" <<'PYEOF'
import json, sys, os

config_file = sys.argv[1]
platform = sys.argv[2]

input_data = json.loads(os.environ.get("HOOK_INPUT", "{}"))
hook_event = input_data.get("hook_event_name", "")

try:
    with open(config_file) as f:
        config = json.load(f)
except Exception:
    config = {}

def get_section(config, *keys):
    for k in keys:
        if k in config:
            return config[k]
    return {}

def sound_file(section, platform):
    if platform == "linux":
        return section.get("sound_file_linux", section.get("sound_file", ""))
    else:
        return section.get("sound_file_macos", section.get("sound_file", ""))

click_to_focus = str(config.get("click_to_focus", False)).lower()

if hook_event == "PermissionRequest":
    section = get_section(config, "permission_request", "permission_prompt")
    enabled = str(section.get("enabled", False)).lower()
    sound = str(section.get("sound", False)).lower()
    sf = sound_file(section, platform)
    title = section.get("title", "Claude Code")

    # Build rich message from tool_name + tool_input
    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    if tool_name == "Bash":
        cmd = tool_input.get("command", "")
        msg = ("Run: " + cmd)[:82]
    elif tool_name in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
        path = tool_input.get("file_path", tool_input.get("notebook_path", ""))
        fname = os.path.basename(path) if path else tool_name
        msg = "Edit: " + fname
    elif tool_name:
        msg = "Use tool: " + tool_name
    else:
        msg = section.get("message", "Permission needed")

    print(f"ENABLED={enabled}")
    print(f"SOUND={sound}")
    print(f"SOUND_FILE={sf}")
    print(f"TITLE={title}")
    print(f"MESSAGE={msg}")
    print(f"CLICK_TO_FOCUS={click_to_focus}")

elif hook_event == "Notification":
    notif_type = input_data.get("notification_type", "")
    section = get_section(config, notif_type)
    enabled = str(section.get("enabled", False)).lower()
    sound = str(section.get("sound", False)).lower()
    sf = sound_file(section, platform)
    title = section.get("title", "Claude Code")
    msg = section.get("message", "")
    print(f"ENABLED={enabled}")
    print(f"SOUND={sound}")
    print(f"SOUND_FILE={sf}")
    print(f"TITLE={title}")
    print(f"MESSAGE={msg}")
    print(f"CLICK_TO_FOCUS={click_to_focus}")

elif hook_event == "Stop":
    section = get_section(config, "stop")
    enabled = str(section.get("enabled", False)).lower()
    sound = str(section.get("sound", False)).lower()
    sf = sound_file(section, platform)
    title = section.get("title", "Claude Code")

    # Try to summarize last assistant message from transcript
    msg = ""
    transcript_path = input_data.get("transcript_path", "")
    if transcript_path and os.path.isfile(transcript_path):
        try:
            last_text = ""
            with open(transcript_path) as tf:
                for line in tf:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        entry = json.loads(line)
                    except Exception:
                        continue
                    if entry.get("role") == "assistant":
                        content = entry.get("content", [])
                        if isinstance(content, list):
                            for block in content:
                                if isinstance(block, dict) and block.get("type") == "text":
                                    last_text = block.get("text", "")
                        elif isinstance(content, str):
                            last_text = content
            if last_text:
                msg = last_text[:100].replace("\n", " ")
        except Exception:
            pass

    if not msg:
        msg = section.get("message", "Task completed")

    print(f"ENABLED={enabled}")
    print(f"SOUND={sound}")
    print(f"SOUND_FILE={sf}")
    print(f"TITLE={title}")
    print(f"MESSAGE={msg}")
    print(f"CLICK_TO_FOCUS={click_to_focus}")

else:
    print("ENABLED=false")
PYEOF
  ) || echo "ENABLED=false"

  # Parse the result into exported variables
  ENABLED=false; SOUND=false; SOUND_FILE=""; TITLE=""; MESSAGE=""; CLICK_TO_FOCUS=false

  while IFS='=' read -r key value; do
    case "$key" in
      ENABLED)         ENABLED="$value" ;;
      SOUND)           SOUND="$value" ;;
      SOUND_FILE)      SOUND_FILE="$value" ;;
      TITLE)           TITLE="$value" ;;
      MESSAGE)         MESSAGE="$value" ;;
      CLICK_TO_FOCUS)  CLICK_TO_FOCUS="$value" ;;
    esac
  done <<< "$result"

  export ENABLED SOUND SOUND_FILE TITLE MESSAGE CLICK_TO_FOCUS
}
