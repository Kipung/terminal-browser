#!/usr/bin/env bash
# Adds a config-file include line to ~/.config/ghostty/config pointing at this
# folder's ghostty.conf. Idempotent: safe to run again.
set -euo pipefail

ADDON_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF="$ADDON_DIR/ghostty.conf"
GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
INCLUDE_LINE="config-file = $CONF"

mkdir -p "$(dirname "$GHOSTTY_CONFIG")"
touch "$GHOSTTY_CONFIG"

if grep -qF "$INCLUDE_LINE" "$GHOSTTY_CONFIG"; then
  echo "Already installed (include line present in $GHOSTTY_CONFIG):"
  echo "  $INCLUDE_LINE"
else
  printf '\n# ghostty-browser-split addon\n%s\n' "$INCLUDE_LINE" >> "$GHOSTTY_CONFIG"
  echo "Added to $GHOSTTY_CONFIG:"
  echo "  $INCLUDE_LINE"
fi

# Clean up any inline copies of this addon's keybinds (only when the include
# is active, so we never delete keybinds the addon doesn't provide).
# Note: avoid \+ in ERE — BSD grep handles it inconsistently.
if grep -q 'keybind = cmd+shift[n]=' "$GHOSTTY_CONFIG" && grep -qF "$INCLUDE_LINE" "$GHOSTTY_CONFIG"; then
  grep -v 'keybind = cmd+shift[n]=' "$GHOSTTY_CONFIG" > "$GHOSTTY_CONFIG.tmp"
  mv "$GHOSTTY_CONFIG.tmp" "$GHOSTTY_CONFIG"
  echo "Removed old inline keybind lines (the addon file now provides them)."
fi

echo
echo "Reload Ghostty config with Cmd+Shift+, to activate."
