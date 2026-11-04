-- WezTerm addon for terminal-browser (macOS + Linux).
-- install.sh links this file into ~/.config/wezterm/ and appends to
-- ~/.config/wezterm/wezterm.lua:
--     pcall(require, "terminal_browser_addon")
--
-- One press (Ctrl+Shift+N) opens the browser directly in a new right split
-- via SpawnCommandInNewSplit — wezterm can chain, so nothing to type.

local wezterm = require 'wezterm'

return {
  apply_to_config = function(config, _)
    config.keys = config.keys or {}
    table.insert(config.keys, {
      key = 'n',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.SpawnCommandInNewSplit({
        direction = 'Right',
        args = { 'terminal-browser', 'open', 'http://localhost:3000' },
      }),
    })
  end,
}
