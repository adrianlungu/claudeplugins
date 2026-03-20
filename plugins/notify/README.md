# Claude Code Notify Plugin

Native desktop notifications with sound for Claude Code events — macOS and Linux.

## What It Does

Sends a banner notification (with optional sound) for three events:

| Event | Notification Content | Default Sound |
|-------|---------------------|---------------|
| Permission request | Rich: `Run: npm install`, `Edit: app.js`, `Use tool: WebSearch` | Ping |
| Idle/waiting for input | "Waiting for your input" | Blow |
| Task completed (Stop) | Last assistant message (truncated to 100 chars) | Glass |

Clicking a notification focuses the terminal window (requires `alerter` on macOS; `dunstify`/`xdotool` on Linux).

## Installation

### Via Claude Code plugins

```sh
claude plugins add /path/to/notify
```

### Manual

Copy this directory to `~/.claude/plugins/notify/` and add the hooks to your `~/.claude/settings.json`.

## Requirements

### macOS

- macOS (uses `osascript` and `afplay`)
- Python 3 (`/usr/bin/python3`, ships with macOS)
- `alerter` (optional, for Claude icon + click-to-focus):
  ```sh
  brew install alerter
  ```

### Linux

- Python 3
- Notification daemon: `dunstify` (recommended) or `notify-send`
  ```sh
  # Debian/Ubuntu
  sudo apt install dunst libnotify-bin
  # Arch
  sudo pacman -S dunst libnotify
  ```
- Sound playback (any one of): `paplay` (PulseAudio), `aplay` (ALSA), `ffplay`, `mpv`
- Click-to-focus on X11: `xdotool` or `wmctrl`
  ```sh
  sudo apt install xdotool
  ```
- Click-to-focus on Sway/Wayland: `swaymsg` (ships with Sway)

## Configuration

Edit `config.json` in the plugin root:

```json
{
  "click_to_focus": true,

  "permission_request": {
    "enabled": true,
    "sound": true,
    "sound_file_macos": "/System/Library/Sounds/Ping.aiff",
    "sound_file_linux": "/usr/share/sounds/freedesktop/stereo/bell.oga",
    "title": "Claude Code",
    "message": "Permission needed"
  },
  "idle_prompt": {
    "enabled": true,
    "sound": true,
    "sound_file_macos": "/System/Library/Sounds/Blow.aiff",
    "sound_file_linux": "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga",
    "title": "Claude Code",
    "message": "Waiting for your input"
  },
  "stop": {
    "enabled": true,
    "sound": true,
    "sound_file_macos": "/System/Library/Sounds/Glass.aiff",
    "sound_file_linux": "/usr/share/sounds/freedesktop/stereo/complete.oga",
    "title": "Claude Code",
    "message": "Task completed"
  }
}
```

### Fields

- `click_to_focus` — clicking the notification brings the terminal to the foreground
- `enabled` — `true`/`false` to turn the notification on or off
- `sound` — `true`/`false` to play a sound
- `sound_file_macos` / `sound_file_linux` — platform-specific sound file path (falls back to `sound_file` for backward compatibility)
- `title` — notification title
- `message` — fallback notification body (overridden by rich content for `permission_request` and `stop`)

## Claude Icon (macOS)

Install `alerter` to show the Claude icon as a notification thumbnail:

```sh
brew install alerter
```

On first run, macOS prompts for notification permission — approve it. Without `alerter`, notifications still work via `osascript` without the custom icon.

## Manual Testing

Run from the plugin root directory (`CLAUDE_PLUGIN_ROOT=$(pwd)`):

```sh
# PermissionRequest — rich message from tool
echo '{"hook_event_name":"PermissionRequest","tool_name":"Bash","tool_input":{"command":"npm install"}}' \
  | CLAUDE_PLUGIN_ROOT=$(pwd) ./hooks/notify.sh

# PermissionRequest — file edit
echo '{"hook_event_name":"PermissionRequest","tool_name":"Edit","tool_input":{"file_path":"/src/app.js"}}' \
  | CLAUDE_PLUGIN_ROOT=$(pwd) ./hooks/notify.sh

# Idle prompt
echo '{"hook_event_name":"Notification","notification_type":"idle_prompt"}' \
  | CLAUDE_PLUGIN_ROOT=$(pwd) ./hooks/notify.sh

# Stop — with transcript summary
echo '{"role":"assistant","content":[{"type":"text","text":"Refactored the auth module"}]}' > /tmp/transcript.jsonl
echo '{"hook_event_name":"Stop","transcript_path":"/tmp/transcript.jsonl"}' \
  | CLAUDE_PLUGIN_ROOT=$(pwd) ./hooks/notify.sh

# Stop — no transcript (uses fallback message)
echo '{"hook_event_name":"Stop"}' \
  | CLAUDE_PLUGIN_ROOT=$(pwd) ./hooks/notify.sh
```

## Available macOS System Sounds

Located in `/System/Library/Sounds/`: `Basso`, `Blow`, `Bottle`, `Frog`, `Funk`, `Glass`, `Hero`, `Morse`, `Ping`, `Pop`, `Purr`, `Sosumi`, `Submarine`, `Tink` (all `.aiff`).
