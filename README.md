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

## Requirements / platforms

Everything targets **cmux-tui** (the terminal multiplexer), the same on every platform:

- **Linux / VPS** (x64, arm64): Node.js 18+, then `npm install -g cmux` (done by `setup-cmux.sh`).
- **macOS**: the same npm package, or the copy bundled in `cmux.app` (`Contents/Resources/bin/cmux-tui`). `setup-cmux.sh` finds it automatically.
- `cmux-find.sh` resolves the binary: `$CMUX_BIN`, `cmux-tui`/`cmux` in PATH, npm global bin, the app bundle. It checks the binary really is the multiplexer, because inside cmux.app the `cmux` in PATH is the GUI's CLI, a different program.
- `cmux-stats.sh`: CPU/RAM/load on Linux (`/proc`) and macOS (`top`, `vm_stat`); empty segment elsewhere.
- `gpu-stats.sh`: NVIDIA, AMD, Intel, Raspberry Pi; silent on macOS and GPU-less hosts.
- `bash` is needed by `setup-cmux.sh`, `cmux-workspaces.sh`, `gpu-stats.sh` (Alpine: `apk add bash`). The stats script is plain POSIX `sh`.
- No Node.js (old or minimal systems)? Use [universal-tmux](https://github.com/Quaerendir/universal-tmux).

## Extras

`extras/cmux-app-workspaces.py` is macOS-only and optional: it builds workspaces in the **cmux.app GUI** (a different program from cmux-tui, with its own CLI) from the same `workspaces.conf`. Run it from a terminal inside the app; `--tmux` puts a tmux session (and its status bar) in each workspace.

## License

MIT
