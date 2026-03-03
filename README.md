# Claude Code Notify Plugin

Native macOS notifications with sound for Claude Code events. Stay informed while working in other apps.

## What It Does

Sends a macOS banner notification (with optional sound) for three events:

| Event | Default Message | Default Sound |
|-------|----------------|---------------|
| Permission prompt | "Permission needed" | Ping.aiff |
| Idle/waiting for input | "Waiting for your input" | Blow.aiff |
| Task completed (Stop) | "Task completed" | Glass.aiff |

## Installation

### Via Claude Code plugins

```sh
claude plugins add /path/to/notify
```

### Manual

Copy this directory to `~/.claude/plugins/notify/` and add the hooks to your `~/.claude/settings.json`.

## Configuration

Edit `config.json` in the plugin root to customize each event:

```json
{
  "permission_prompt": {
    "enabled": true,
    "sound": true,
    "sound_file": "/System/Library/Sounds/Ping.aiff",
    "title": "Claude Code",
    "message": "Permission needed"
  }
}
```

### Fields

- `enabled` — `true`/`false` to turn the notification on or off
- `sound` — `true`/`false` to play a sound
- `sound_file` — absolute path to an `.aiff` sound file
- `title` — notification title
- `message` — notification body text

### Disable a Specific Event

Set `"enabled": false` for any event key in `config.json`.

## Available macOS System Sounds

Located in `/System/Library/Sounds/`:

- `Basso.aiff`
- `Blow.aiff`
- `Bottle.aiff`
- `Frog.aiff`
- `Funk.aiff`
- `Glass.aiff`
- `Hero.aiff`
- `Morse.aiff`
- `Ping.aiff`
- `Pop.aiff`
- `Purr.aiff`
- `Sosumi.aiff`
- `Submarine.aiff`
- `Tink.aiff`

## Manual Test

From the plugin root directory:

```sh
# Test a Notification event
echo '{"hook_event_name":"Notification","notification_type":"permission_prompt"}' | CLAUDE_PLUGIN_ROOT=$(pwd) ./hooks/notify.sh

# Test a Stop event
echo '{"hook_event_name":"Stop"}' | CLAUDE_PLUGIN_ROOT=$(pwd) ./hooks/notify.sh
```

## Requirements

- macOS (uses `osascript` and `afplay`)
- Python 3 (`/usr/bin/python3`, ships with macOS)
