#!/usr/bin/env bash
# Linux notification + sound implementation

send_notification() {
  local title="$1"
  local message="$2"
  local icon="${3:-}"
  local click_to_focus="${4:-false}"

  local icon_arg=""
  if [[ -f "$icon" ]]; then
    icon_arg="$icon"
  fi

  if command -v dunstify &>/dev/null; then
    if [[ "$click_to_focus" == "true" ]]; then
      # Run dunstify in background subshell; focus terminal after click (action=0)
      (
        action=$(dunstify --action="0,Focus" ${icon_arg:+--icon="$icon_arg"} "$title" "$message" 2>/dev/null || echo "")
        if [[ "$action" == "0" ]]; then
          _focus_terminal
        fi
      ) &
    else
      dunstify ${icon_arg:+--icon="$icon_arg"} "$title" "$message" &>/dev/null &
    fi

  elif command -v notify-send &>/dev/null; then
    # notify-send >= 0.8 supports --action; try it, fall back silently
    if [[ "$click_to_focus" == "true" ]] && notify-send --help 2>&1 | grep -q -- '--action'; then
      (
        action=$(notify-send ${icon_arg:+--icon="$icon_arg"} --action="focus=Focus" --wait "$title" "$message" 2>/dev/null || echo "")
        if [[ "$action" == "focus" ]]; then
          _focus_terminal
        fi
      ) &
    else
      notify-send ${icon_arg:+--icon="$icon_arg"} "$title" "$message" &>/dev/null &
    fi

  else
    echo "notify plugin: no notification tool found (install dunstify or notify-send)" >&2
  fi
}

play_sound() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  if command -v paplay &>/dev/null; then
    paplay "$file" &
  elif command -v aplay &>/dev/null; then
    aplay "$file" &>/dev/null &
  elif command -v ffplay &>/dev/null; then
    ffplay -nodisp -autoexit "$file" &>/dev/null &
  elif command -v mpv &>/dev/null; then
    mpv --no-video "$file" &>/dev/null &
  fi
}

_focus_terminal() {
  local pid=$$

  # Wayland / Sway
  if [[ -n "${SWAYSOCK:-}" ]] && command -v swaymsg &>/dev/null; then
    swaymsg "[pid=${PPID}] focus" &>/dev/null || true
    return
  fi

  # X11 via xdotool
  if [[ -n "${DISPLAY:-}" ]] && command -v xdotool &>/dev/null; then
    xdotool search --pid "$PPID" windowactivate --sync &>/dev/null || true
    return
  fi

  # X11 via wmctrl (fallback)
  if [[ -n "${DISPLAY:-}" ]] && command -v wmctrl &>/dev/null; then
    # Get window belonging to parent PID
    local wid
    wid=$(wmctrl -lp | awk -v ppid="$PPID" '$3==ppid{print $1; exit}')
    if [[ -n "$wid" ]]; then
      wmctrl -ia "$wid" &>/dev/null || true
    fi
    return
  fi

  # GNOME Wayland — no reliable API, skip gracefully
  return 0
}
