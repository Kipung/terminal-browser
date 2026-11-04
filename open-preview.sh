#!/usr/bin/env bash
# open-preview.sh — open a live site preview in a NATIVE split of your HOST
# terminal (Ghostty, kitty, WezTerm, tmux, VS Code) — macOS and Linux.
# Agent-callable: no keypresses needed from the human when it can help it.
#
#   ./open-preview.sh                        # URL from addon.conf / arg
#   ./open-preview.sh http://localhost:3000/some/page
#
# Why native splits? Inside a multiplexer (herdr & co) terminal-browser's
# --split asks the MULTIPLEXER for a pane, and a kitty-graphics pane inside
# one re-triggers the frame-flood lag (the multiplexer replays its whole
# scene to the host terminal on every text frame). So:
#  - Not inside a multiplexer: terminal-browser's built-in --split already
#    asks the host terminal for a native pane. Correct flow, used as-is.
#  - Inside herdr: drive the host terminal directly —
#      wezterm:  `wezterm cli split-pane` + send-text   (macOS + Linux)
#      kitty:    `kitty @ launch --type=split ...`      (needs allow_remote_control)
#      ghostty:  AppleScript keystrokes                 (macOS only, needs
#                Accessibility permission for Ghostty)
#    Any failure falls back to printing the manual keypress flow.
set -euo pipefail

ADDON_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=addon.conf
[ -f "$ADDON_DIR/addon.conf" ] && . "$ADDON_DIR/addon.conf"
URL="${1:-${PREVIEW_URL:-http://localhost:3000}}"

if ! curl -sf -o /dev/null "$URL"; then
  echo "warning: $URL is not answering — is your dev server up?" >&2
fi

# ---- Host detection (env markers usually survive multiplexers) -------------
host=""
if   [ -n "${KITTY_WINDOW_ID:-}" ];        then host=kitty
elif [ -n "${WEZTERM_PANE:-}" ];           then host=wezterm
elif [ -n "${GHOSTTY_RESOURCES_DIR:-}" ];  then host=ghostty
elif [ "${TERM_PROGRAM:-}" = "vscode" ];   then host=vscode
fi

in_mux=0
[ "${TERM_PROGRAM:-}" = "herdr" ] && in_mux=1
# Plain tmux: terminal-browser's own --split drives tmux — that's supported,
# so tmux alone does NOT set in_mux. Only herdr-style floods do.

# ---- Path 1: not in herdr — terminal-browser handles every host natively --
if [ "$in_mux" -eq 0 ]; then
  exec terminal-browser open "$URL" --split right --size 0.4
fi

# ---- Path 2: inside herdr — ask the HOST terminal for a native split ------

try_wezterm() {
  command -v wezterm >/dev/null || return 1
  local pane
  pane=$(wezterm cli split-pane --percentage 40 --right 2>/dev/null) \
    || pane=$(wezterm cli split-pane --percentage 40 -h 2>/dev/null) \
    || return 1
  [ -n "$pane" ] || return 1
  wezterm cli send-text --pane-id "$pane" --press-enter \
    -- "terminal-browser open $URL" 2>/dev/null
}

try_kitty() {
  command -v kitty >/dev/null || return 1
  kitty @ launch --type=split --location=right --cwd=current \
    terminal-browser open "$URL" 2>/dev/null
}

try_ghostty_mac() {
  [ "$(uname)" = "Darwin" ] || return 1
  command -v osascript >/dev/null || return 1
  osascript - "$URL" <<'EOF'
on run argv
  tell application "System Events"
    -- Keystrokes go to whatever app is frontmost, so make sure it's Ghostty.
    if name of (first process whose frontmost is true) is not "ghostty" then
      do shell script "open -a ghostty"
      delay 0.3
    end if
    tell process "ghostty"
      keystroke "d" using command down -- split right (native, outside herdr)
      delay 0.4
      keystroke "terminal-browser open " & (item 1 of argv)
      key code 36                      -- Enter
    end tell
  end tell
end run
EOF
}

opened=""
case "$host" in
  wezterm) try_wezterm  && opened="WezTerm (wezterm cli)" ;;
  kitty)   try_kitty    && opened="kitty (remote control)" ;;
  ghostty) try_ghostty_mac && opened="Ghostty (AppleScript)" ;;
esac
# Order-independent retry for env-detection misses:
if [ -z "$opened" ]; then
  for t in try_wezterm try_kitty try_ghostty_mac; do
    if "$t"; then opened="$t"; break; fi
  done
fi

if [ -n "$opened" ]; then
  echo "Preview opening in a native $opened split: $URL"
  exit 0
fi

# ---- Fallback: hand it to the human ---------------------------------------
cat >&2 <<EOF
Could not drive the host terminal from inside the multiplexer.
Manual flow (fast, native split — no frame flood):
  1. Open your terminal's native right split
     (Ghostty: Cmd/Ctrl+Shift+... see docs; kitty: built-in Ctrl+Shift+Enter or your map;
      wezterm: Ctrl+Alt+" or your keytable)
  2. Focus it, run:  terminal-browser open $URL
Tip: install.sh wires a one-press hotkey for your terminal; for the Ghostty
macOS path grant Accessibility permission (System Settings > Privacy &
Security > Accessibility > Ghostty).
EOF
exit 1
