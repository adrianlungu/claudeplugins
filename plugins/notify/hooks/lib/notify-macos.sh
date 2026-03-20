#!/usr/bin/env bash
# macOS notification + sound implementation

send_notification() {
  local title="$1"
  local message="$2"
  local icon="${3:-}"
  local click_to_focus="${4:-false}"

  if command -v alerter &>/dev/null && [[ -f "$icon" ]]; then
    local alerter_args=(
      --title "$title"
      --message "$message"
      --app-icon "$icon"
      --timeout 5
    )

    if [[ "$click_to_focus" == "true" ]]; then
      local bundle_id
      bundle_id="$(_macos_terminal_bundle_id)"
      if [[ -n "$bundle_id" ]]; then
        alerter_args+=(-execute "osascript -e 'tell application id \"${bundle_id}\" to activate'")
      fi
    fi

    alerter "${alerter_args[@]}" &>/dev/null || true
  else
    /usr/bin/osascript -e "display notification \"${message}\" with title \"${title}\"" &>/dev/null || true
  fi
}

play_sound() {
  local file="$1"
  if [[ -f "$file" ]]; then
    /usr/bin/afplay "$file" &
  fi
}

# Map $TERM_PROGRAM to macOS bundle IDs
_macos_terminal_bundle_id() {
  case "${TERM_PROGRAM:-}" in
    Apple_Terminal)   echo "com.apple.Terminal" ;;
    iTerm.app)        echo "com.googlecode.iterm2" ;;
    vscode)           echo "com.microsoft.VSCode" ;;
    WarpTerminal)     echo "dev.warp.Warp-Stable" ;;
    ghostty)          echo "com.mitchellh.ghostty" ;;
    *)
      # Check TERM_PROGRAM_VERSION for other hints; default to Terminal
      echo "com.apple.Terminal"
      ;;
  esac
}
