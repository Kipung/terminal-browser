#!/usr/bin/env bash
# Wire the addon hotkey into whichever supported terminals you have:
#   ghostty, kitty, wezterm, tmux — each gets ONE marker-commented line in
# its own config file; the keybinds themselves live in configs/ here, so
# edits in this repo are live. Idempotent: safe to re-run.
#
#   ./install.sh              # auto: every supported terminal found on PATH
#   ./install.sh --all        # force all four, PATH or not
#   ./install.sh --only kitty,tmux
set -euo pipefail

ADDON_DIR="$(cd "$(dirname "$0")" && pwd)"

targets=""
case "${1:-}" in
  --only)
    targets="${2:?usage: --only ghostty[,kitty,wezterm,tmux]}" ;;
  --all)
    targets="ghostty,kitty,wezterm,tmux" ;;
  "")
    for t in ghostty kitty wezterm tmux; do
      command -v "$t" >/dev/null 2>&1 && targets="${targets:+$targets,}$t"
    done ;;
  *)
    echo "usage: $0 [--only host[,host...]] [--all]" >&2; exit 2 ;;
esac

if [ -z "$targets" ]; then
  echo "No supported terminal (ghostty, kitty, wezterm, tmux) found on PATH." >&2
  echo "Install one, or run with --all to wire configs anyway." >&2
  exit 1
fi

marker() { printf '# terminal-browser addon (%s)' "$1"; }

add_line() { # <config-file> <marker> <payload-line>
  local file="$1" mark="$2" line="$3"
  mkdir -p "$(dirname "$file")"; touch "$file"
  if grep -qxF "$line" "$file"; then
    echo "  already wired: $file"
  else
    printf '%s\n%s\n' "$mark" "$line" >> "$file"
    echo "  wired:         $file"
  fi
}

IFS=','; for t in $targets; do
case "$t" in
  ghostty)
    echo "ghostty:"
    add_line "$HOME/.config/ghostty/config" "$(marker ghostty)" \
      "config-file = $ADDON_DIR/configs/ghostty.conf"
    echo "  reload: Cmd/Ctrl+Shift+, in Ghostty" ;;
  kitty)
    echo "kitty:"
    add_line "$HOME/.config/kitty/kitty.conf" "$(marker kitty)" \
      "include $ADDON_DIR/configs/kitty.conf"
    echo "  reload: Ctrl+Shift+F5 in kitty" ;;
  tmux)
    echo "tmux:"
    add_line "$HOME/.tmux.conf" "$(marker tmux)" \
      "source-file $ADDON_DIR/configs/tmux.conf"
    echo "  reload: in tmux, run  : source ~/.tmux.conf" ;;
  wezterm)
    echo "wezterm:"
    mkdir -p "$HOME/.config/wezterm"
    ln -sf "$ADDON_DIR/configs/wezterm-addon.lua" \
           "$HOME/.config/wezterm/terminal_browser_addon.lua"
    echo "  linked module: ~/.config/wezterm/terminal_browser_addon.lua"
    W="$HOME/.config/wezterm/wezterm.lua"
    if [ ! -f "$W" ]; then
      cat > "$W" <<'EOF'
-- terminal-browser addon (wezterm)
local wezterm = require 'wezterm'
local config = wezterm.config_builder()
require("terminal_browser_addon").apply_to_config(config)
return config
EOF
      echo "  created $W with the addon applied"
    elif grep -qF 'terminal_browser_addon' "$W"; then
      echo "  already wired: $W"
    else
      echo "  you have an existing wezterm.lua — add these 2 lines inside it:"
      echo "    require('terminal_browser_addon').apply_to_config(config)"
      echo "  (before its 'return config')"
    fi
    echo "  reload: wezterm picks up saved config automatically" ;;
  *)
    echo "unknown target: $t (ghostty|kitty|wezterm|tmux)" >&2; exit 2 ;;
esac
done

echo
echo "Done. Keybinds: configs/<terminal>.conf in this repo — edit there, the"
echo "URL is baked into each snippet. Agent path: ./open-preview.sh [url]."
