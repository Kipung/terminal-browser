#!/usr/bin/env bash
# Removes this addon's include line from ~/.config/ghostty/config. Idempotent.
set -euo pipefail

ADDON_DIR="$(cd "$(dirname "$0")" && pwd)"
GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
INCLUDE_LINE="config-file = $ADDON_DIR/ghostty.conf"

if [ ! -f "$GHOSTTY_CONFIG" ]; then
  echo "No Ghostty config found at $GHOSTTY_CONFIG — nothing to do."
  exit 0
fi

if grep -qF "$INCLUDE_LINE" "$GHOSTTY_CONFIG"; then
  grep -vF "$INCLUDE_LINE" "$GHOSTTY_CONFIG" > "$GHOSTTY_CONFIG.tmp"
  grep -v '^# terminal-browser ghostty-split addon$' "$GHOSTTY_CONFIG.tmp" > "$GHOSTTY_CONFIG" || true
  rm -f "$GHOSTTY_CONFIG.tmp"
  echo "Removed the addon include line from $GHOSTTY_CONFIG."
  echo "Reload Ghostty config with Cmd+Shift+, to apply."
else
  echo "Addon include line not found — already uninstalled."
fi
