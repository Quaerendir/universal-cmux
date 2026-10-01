# universal-cmux

cmux counterpart of [universal-tmux](https://github.com/Quaerendir/universal-tmux): drop it on any machine and get the same prefix, split keys, dark theme and hardware-aware status bar in [cmux](https://github.com/manaflow-ai/cmux/tree/main/cmux-tui) (`npm install -g cmux`).

## What maps to what

| universal-tmux | universal-cmux |
|---|---|
| `tmux-universal.conf` | `cmux-universal.json` → `~/.config/cmux/cmux-tui.json` |
| `gpu-stats.sh` in `status-right` `#()` | same script, as a `status_bar.right[].run` segment |
| tmux-cpu plugin | `cmux-stats.sh cpu\|ram\|load` (reads `/proc`) |
| resurrect + continuum | **not needed** — cmux keeps a detached session owner and a durable on-disk journal |
| hand-written session scripts | `cmux-workspaces.sh` + `workspaces.conf` |
| `setup-tmux.sh` | `setup-cmux.sh` |

tmux session → cmux **workspace**, tmux window → cmux **screen**.

## Install

```bash
git clone <this repo> && cd universal-cmux
bash setup-cmux.sh
cmux                                   # start / attach
~/.config/cmux/cmux-workspaces.sh up   # build workspaces from workspaces.conf
```

## Workspace spec (`~/.config/cmux/workspaces.conf`)

```
workspace NAME DIR [COMMAND...]   # new workspace, first pane cd's to DIR and runs COMMAND
split right|down [COMMAND...]     # split the last pane of that workspace
```

`cmux-workspaces.sh [-s session] [-f file] [up|list]` is idempotent: existing workspace names are skipped.

## Keybindings (prefix `C-a`)

| Key | Action |
|---|---|
| `prefix + -` / `\|` | split down / right |
| `prefix + z` / `+` | zoom pane |
| `prefix + x` / `X` | close pane / tab |
| `prefix + c` / `&` | new / close screen |
| `prefix + C-h` / `C-l` | previous / next screen |
| `prefix + W` / `D` | new / close workspace |
| `Alt + arrows` (or `hjkl`) | pane navigation |
| `Alt + =` / `Alt + -` | resize |
| `prefix + ?` | full shortcut list |
| `prefix + d` | detach |

## Not carried over

- `prefix + m` (main-vertical): cmux has its own auto layout on `Alt-n`.
- `Shift+Alt+arrows` directional resize: cmux only has grow/shrink of the focused split.
- Paste buffer (`prefix + ]`) and pane-number jump (`prefix + q`): not implemented in cmux-tui.
- Mouse and vi copy-mode settings: no config keys documented.

## Requirements

- Node.js 18+ (for the npm `cmux` package; Linux x64/arm64, macOS)
- `cmux-stats.sh` CPU/RAM need Linux `/proc` (segment stays empty elsewhere)

## License

MIT
