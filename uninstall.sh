#!/usr/bin/env bash
# Remove everything install.sh added (marker-commented lines in each terminal
# config + the wezterm module link). Leaves your own config content intact.
# Idempotent: safe to re-run.
set -euo pipefail

ADDON_DIR="$(cd "$(dirname "$0")" && pwd)"

strip_lines() { # <config-file> <line1> [<line2> ...] — removes exact lines + our markers
  local file="$1"; shift
  [ -f "$file" ] || { echo "  no config at $file — nothing to do"; return; }
  local before after
  before=$(wc -l < "$file")
  grep -vxF -e "$1" "${@:2}" -e '# terminal-browser addon (ghostty)' \
    -e '# terminal-browser addon (kitty)' -e '# terminal-browser addon (tmux)' \
    "$file" > "$file.tmp" || true
  mv "$file.tmp" "$file"
  after=$(wc -l < "$file")
  if [ "$before" -ne "$after" ]; then
    echo "  cleaned: $file ($((before - after)) line(s) removed)"
  else
    echo "  already clean: $file"
  fi
}

echo "ghostty:"
strip_lines "$HOME/.config/ghostty/config" \
  "config-file = $ADDON_DIR/configs/ghostty.conf"

echo "kitty:"
strip_lines "$HOME/.config/kitty/kitty.conf" \
  "include $ADDON_DIR/configs/kitty.conf"

echo "tmux:"
strip_lines "$HOME/.tmux.conf" \
  "source-file $ADDON_DIR/configs/tmux.conf"

echo "wezterm:"
rm -f "$HOME/.config/wezterm/terminal_browser_addon.lua"
echo "  unlinked module: ~/.config/wezterm/terminal_browser_addon.lua"
W="$HOME/.config/wezterm/wezterm.lua"
if [ -f "$W" ] && head -n1 "$W" | grep -qxF -- '-- terminal-browser addon (wezterm)'; then
  # install.sh created this whole file — remove it. (If you had your own
  # wezterm.lua, install.sh never edited it, so there's nothing to undo.)
  rm -f "$W"; echo "  removed $W (created by install.sh)"
else
  echo "  wezterm.lua untouched (not created by install.sh)"
fi

echo
echo "Done. Reload each terminal's config to apply (Cmd/Ctrl+Shift+, ghostty,"
echo "Ctrl+Shift+F5 kitty, ':source ~/.tmux.conf' tmux; wezterm auto-reloads)."
