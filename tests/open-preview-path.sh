#!/usr/bin/env bash
# Checks which launch path open-preview.sh picks. Side-effect commands are stubbed,
# so nothing opens. Run: bash tests/open-preview-path.sh
set -u
SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/open-preview.sh"
STUBS="$(mktemp -d)"; trap 'rm -rf "$STUBS"' EXIT
LOG="$STUBS/calls.log"
for cmd in terminal-browser osascript curl; do
  printf '#!/bin/sh\necho "%s $*" >> "%s"\n' "$cmd" "$LOG" > "$STUBS/$cmd"
  chmod +x "$STUBS/$cmd"
done
fails=0

expect() {
  local want="$1" label="$2"; shift 2
  : > "$LOG"
  env -i HOME="$HOME" PATH="$STUBS:/usr/bin:/bin" "$@" bash "$SCRIPT" http://localhost:9 >/dev/null 2>&1
  local got; got="$(grep -v '^curl' "$LOG" | head -1 | cut -d' ' -f1)"
  if [ "$got" = "$want" ]; then echo "ok   $label"; else echo "FAIL $label: expected $want, got ${got:-nothing}"; fails=$((fails + 1)); fi
}

expect osascript        "herdr pane (HERDR_ENV, empty TERM_PROGRAM) uses a native Ghostty split" HERDR_ENV=1 HERDR_PANE_ID=w1:p1 GHOSTTY_RESOURCES_DIR=/x
expect osascript        "herdr pane detected by HERDR_PANE_ID alone"                              HERDR_PANE_ID=w1:p1 GHOSTTY_RESOURCES_DIR=/x
expect osascript        "TERM_PROGRAM=herdr still detected"                                      TERM_PROGRAM=herdr GHOSTTY_RESOURCES_DIR=/x
expect terminal-browser "plain Ghostty uses terminal-browser's own split"                         GHOSTTY_RESOURCES_DIR=/x
exit "$fails"
