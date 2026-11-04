#!/usr/bin/env bash
# open-preview.sh — open a live site preview in a NATIVE Ghostty split.
# Agent-callable: no keypresses needed from the human.
#
#   ./open-preview.sh                        # http://localhost:3000
#   ./open-preview.sh http://localhost:3000/some/page
#
# Two paths:
#  - Inside herdr (TERM_PROGRAM=herdr): terminal-browser's own --split would ask
#    HERDR for a pane, and a kitty-graphics pane inside herdr re-triggers the
#    frame-flood lag (herdr replays its whole scene to the host per text frame).
#    So we drive GHOSTTY itself via AppleScript: press Cmd+D (native split),
#    then type the command into the new split. Needs Accessibility permission
#    for Ghostty (System Settings > Privacy & Security > Accessibility).
#  - Outside herdr (native Ghostty split, kitty, wezterm, tmux, VS Code):
#    terminal-browser's built-in --split works and is preferred — no keystrokes.
set -euo pipefail

URL="${1:-http://localhost:3000}"

if ! curl -sf -o /dev/null "$URL"; then
  echo "warning: $URL is not answering — is your dev server up?" >&2
fi

if [ "${TERM_PROGRAM:-}" != "herdr" ]; then
  # Not inside herdr: let terminal-browser ask the host terminal for the split.
  exec terminal-browser open "$URL" --split right --size 0.4
fi

osascript - "$URL" <<'EOF'
on run argv
  tell application "System Events"
    -- Keystrokes go to whatever app is frontmost, so make sure it's Ghostty.
    if name of (first process whose frontmost is true) is not "ghostty" then
      do shell script "open -a ghostty"
      delay 0.3
    end if
    tell process "ghostty"
      keystroke "d" using command down -- Cmd+D: native Ghostty split (right)
      delay 0.4
      keystroke "terminal-browser open " & (item 1 of argv)
      key code 36                      -- Enter
    end tell
  end tell
end run
EOF

echo "Preview opening in a native Ghostty split: $URL"
