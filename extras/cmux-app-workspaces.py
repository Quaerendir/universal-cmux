#!/usr/bin/env python3
"""cmux-app-workspaces.py — build workspaces in the cmux macOS app from workspaces.conf.

The macOS app (cmux.app) is not cmux-tui: it has no `cmux workspace create`,
only `cmux new-workspace --layout <json>`. This reads the same spec as
cmux-workspaces.sh and turns each workspace into one --layout call.

Run it from a terminal INSIDE cmux.app (the app's socket rejects outside processes).

Usage: cmux-app-workspaces.py [-f spec] [--dry-run] [--focus] [--tmux]

--tmux  one cmux pane per workspace running a tmux session (splits done by tmux),
        so the universal-tmux status bar (~/.tmux.conf) is shown at the bottom.

Spec (same as cmux-workspaces.sh):
  workspace NAME DIR [COMMAND...]   new workspace; first pane starts in DIR, runs COMMAND
  split right|down [COMMAND...]     split the last pane above it
"""
import argparse, json, os, shlex, subprocess, sys

CMUX = os.environ.get("CMUX_BIN") or "/Applications/cmux.app/Contents/Resources/bin/cmux"


def leaf(cwd, command):
    s = {"type": "terminal", "cwd": cwd}
    if command:
        s["command"] = command
    return {"pane": {"surfaces": [s]}}


def parse(path):
    """-> [(name, dir, tree)]; tree is a leaf or nested split nodes."""
    out, cur = [], None
    for raw in open(path):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        w = shlex.split(line)
        if w[0] == "workspace":
            d = os.path.expanduser(w[2])
            cur = {"name": w[1], "dir": d, "tree": leaf(d, " ".join(w[3:])), "last": None,
                   "ops": [("first", " ".join(w[3:]))]}
            cur["last"] = cur["tree"]
            out.append(cur)
        elif w[0] == "split" and cur:
            direction = {"right": "horizontal", "down": "vertical"}[w[1]]
            new = leaf(cur["dir"], " ".join(w[2:]))
            cur["ops"].append((w[1], " ".join(w[2:])))
            old = dict(cur["last"])  # copy of the leaf being split
            cur["last"].clear()      # turn it into the split node in place
            cur["last"].update({"direction": direction, "split": 0.5, "children": [old, new]})
            cur["last"] = new
        else:
            print(f"skip: {line}", file=sys.stderr)
    return out


def tmux_snippet(ws):
    """Shell line: create the tmux session if missing (splits + commands), then attach."""
    name, d = shlex.quote(ws["name"]), shlex.quote(ws["dir"])
    steps = []  # (tmux args, command typed into the new pane)
    for i, (kind, cmd) in enumerate(ws["ops"]):
        steps.append((kind, cmd))
    t = f"tmux new-session -d -s {name} -c {d}"
    parts = []
    for kind, cmd in steps:
        if kind == "first":
            if cmd:
                parts.append(f"send-keys {shlex.quote(cmd)} Enter")
        else:
            flag = "-h" if kind == "right" else "-v"
            parts.append(f"split-window {flag} -c {d}")
            if cmd:
                parts.append(f"send-keys {shlex.quote(cmd)} Enter")
    if parts:
        t += " \\; " + " \\; ".join(parts)
    # last split leaves focus on the newest pane; focus the first one again
    t += " \\; select-pane -t 0" if len(steps) > 1 else ""
    return f"tmux has-session -t {name} 2>/dev/null || {{ {t}; }}; tmux attach -t {name}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-f", default=os.path.expanduser("~/.config/cmux/workspaces.conf"))
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--tmux", action="store_true", help="run a tmux session per workspace (universal-tmux status bar)")
    ap.add_argument("--focus", action="store_true", help="focus each new workspace")
    a = ap.parse_args()

    existing = ""
    if not a.dry_run:
        r = subprocess.run([CMUX, "list-workspaces"], capture_output=True, text=True,
                           env={**os.environ, "CMUX_QUIET": "1"})
        if r.returncode:
            sys.exit(f"cmux not reachable (run this inside a cmux terminal): {r.stderr.strip()}")
        existing = r.stdout

    for ws in parse(a.f):
        tree = leaf(ws["dir"], tmux_snippet(ws)) if a.tmux else ws["tree"]
        cmd = [CMUX, "new-workspace", "--name", ws["name"], "--cwd", ws["dir"],
               "--layout", json.dumps(tree), "--focus", str(a.focus).lower()]
        if a.dry_run:
            print(shlex.join(cmd))
            continue
        if ws["name"] in existing:
            print(f"skip: '{ws['name']}' exists")
            continue
        r = subprocess.run(cmd, capture_output=True, text=True, env={**os.environ, "CMUX_QUIET": "1"})
        print(("created: " if r.returncode == 0 else "FAILED:  ") + ws["name"],
              r.stderr.strip() if r.returncode else "")


if __name__ == "__main__":
    main()
