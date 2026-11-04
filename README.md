# terminal-browser

**A live, clickable browser preview beside your terminal agents — at full speed, opened
by you with one keypress or by any agent with one command.**

> **Not to be confused with [terminal-browser](https://terminal-browser.dev) itself** —
> this repo packages that excellent tool into a Ghostty workflow: it renders *inside* a
> native Ghostty split so agents can show you live pages without the multiplexer
> graphics frame-flood. Think "addon", not "fork".

If you run coding agents in a terminal multiplexer and you've wished they could just…
*show you the page* they're working on — that's this. `terminal-browser` renders a real
browser inside a terminal pane (kitty graphics protocol). This addon makes it open in a
**native Ghostty split**, side by side with your agents, and wires the whole flow so
agents can launch it themselves.

```
┌─────────────────────────────┬───────────────────┐
│  herdr / tmux               │                   │
│  ┌──────────┬────────────┐  │   browser preview │
│  │ agent 1  │  agent 2   │  │   localhost:3000  │
│  │ streaming│ streaming  │  │   live, clickable │
│  └──────────┴────────────┘  │                   │
└─────────────────────────────┴───────────────────┘
        Cmd+D, Cmd+Shift+N — or the agent does it
```

## Why a *native Ghostty* split and not a multiplexer pane?

Some multiplexers (notably [herdr](https://herdr.dev)) re-emit their entire pane scene —
including any kitty graphics they host — to the host terminal on **every text frame**.
Put a browser inside such a pane next to a streaming agent and the terminal emulator
pins a CPU core, memory balloons by hundreds of MB, and the whole session goes laggy.

A native Ghostty split lives *outside* the multiplexer's compositing entirely: Ghostty
renders the graphics directly, the multiplexer never sees them, and everything stays
fast. This addon is that split-plus-launch flow, packaged.

## Requirements

- [Ghostty](https://ghostty.org) 1.3+ on macOS (keybinds + AppleScript automation)
- [terminal-browser](https://terminal-browser.dev) — `brew install --cask terminal-browser`
- macOS **Accessibility** permission for Ghostty (only for the agent-driven path):
  *System Settings → Privacy & Security → Accessibility → Ghostty*

## Install

```sh
git clone https://github.com/Kipung/terminal-browser
cd terminal-browser
./install.sh
```

`install.sh` appends one line to `~/.config/ghostty/config` — a `config-file` include
pointing at this folder, so everything stays live-editable here:

```
config-file = /path/to/terminal-browser/ghostty.conf
```

Reload the Ghostty config: **Cmd+Shift+,**

Uninstall with `./uninstall.sh` (removes just that line; idempotent both ways).

## Usage

### As a human

1. Dev server up (say, `localhost:3000`).
2. **Cmd+D** — Ghostty's *built-in* "split right" (nothing configured here).
3. Focus the new split, press **Cmd+Shift+N** — the addon's one custom keybind. It
   simply types `terminal-browser open http://localhost:3000` + Enter into that pane.
4. Click and scroll the page normally. Quit the browser with `q` (or Ctrl+C).

> Why two presses? Ghostty 1.3.1 rejects chaining actions onto `new_split` in keybinds
> (`new_split:right,text:…` → InvalidFormat). If action chaining lands upstream, one key
> will be enough.

### As an agent

```sh
./open-preview.sh                       # defaults to http://localhost:3000
./open-preview.sh http://localhost:3000/pricing
```

One command and the agent drives Ghostty itself: presses Cmd+D, then types the launch
command into the new split. Add a line to your project's `AGENTS.md` / `CLAUDE.md`:

> To show a live preview, run `path/to/open-preview.sh [url]`. Never launch
> `terminal-browser` directly from a multiplexer pane — its `--split` creates a pane
> *inside* the multiplexer, which re-triggers the graphics frame flood.

## How `open-preview.sh` picks its path

| You are in… | What happens |
|---|---|
| **Inside herdr** (`TERM_PROGRAM=herdr`) | terminal-browser's own `--split` would ask *herdr* for a pane → frame flood. So the script drives **Ghostty** via AppleScript keystrokes instead → native split, no flood. |
| **Anywhere else** (native Ghostty window, kitty, wezterm, tmux, VS Code) | `terminal-browser open --split right` asks the host terminal for a native pane — already the correct flow, no keystroke injection needed. |

The flood is a multiplexer-compositing problem, not a browser problem — outside herdr,
plain `--split` is fine and the script uses it.

## Files

| File | Purpose |
|---|---|
| `ghostty.conf` | The addon's keybinds, included by your main Ghostty config |
| `open-preview.sh` | Agent-callable opener (auto-detects herdr vs. native context) |
| `install.sh` | Adds the `config-file =` include line (idempotent) |
| `uninstall.sh` | Removes it (idempotent) |

## Troubleshooting

- **Nothing happens on Cmd+Shift+N** — reload Ghostty config with Cmd+Shift+,.
- **Agent path fails with an osascript error** — grant Ghostty Accessibility permission.
- **Browser feels sluggish** — check `~/.config/terminal-browser/settings.json`; a
  `"render.fps"` cap applies only at browser start. Keep it `{}` and restart the browser.
- **CPU pegged / memory ballooning** — a graphics surface ended up inside your
  multiplexer. Close the browser pane (`q`) and it heals instantly; make sure agents use
  `open-preview.sh`, not raw `terminal-browser`.
- **Memory creeping with many previews** — each browser instance costs ~150 MB;
  `terminal-browser ls --all` lists them, `q` closes one, `terminal-browser shutdown` stops all.

## Notes & upstream

- This is a workaround, not a fix: the frame flood is an upstream multiplexer issue
  around re-emitting graphics scenes per text frame. When hosts expose scriptable
  native splits (Ghostty CLI has no `+new-split` action yet), the AppleScript path
  can go away.
- terminal-browser also ships its own agent skills (`terminal-browser setup`). Inside a
  herdr-style multiplexer, be careful: its skill teaches `--split`, which is the trap
  described above.

## License

MIT — see [LICENSE](LICENSE).
