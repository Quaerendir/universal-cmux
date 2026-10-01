#!/bin/bash
# setup-cmux.sh
# Quick deploy of universal cmux config on any machine
# Usage: bash setup-cmux.sh

set -e

echo "=== cmux Universal Setup ==="

# 1. Check / install cmux
if ! command -v cmux &>/dev/null; then
    if command -v npm &>/dev/null; then
        echo "Installing cmux via npm..."
        npm install -g cmux
    else
        echo "ERROR: cmux not installed and npm not found"
        echo "  Install Node.js 18+ first, then: npm install -g cmux"
        exit 1
    fi
fi
echo "cmux: $(cmux --version 2>&1 | head -1)"

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/cmux"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$CFG"

# 2. Backup existing config
if [ -f "$CFG/cmux-tui.json" ]; then
    cp "$CFG/cmux-tui.json" "$CFG/cmux-tui.json.bak.$(date +%Y%m%d%H%M%S)"
    echo "Backup: $CFG/cmux-tui.json -> cmux-tui.json.bak.*"
fi

# 3. Copy files
cp "$SRC/cmux-universal.json" "$CFG/cmux-tui.json"
cp "$SRC/cmux-stats.sh" "$SRC/gpu-stats.sh" "$SRC/cmux-workspaces.sh" "$CFG/"
chmod +x "$CFG/cmux-stats.sh" "$CFG/gpu-stats.sh" "$CFG/cmux-workspaces.sh"
echo "Config  -> $CFG/cmux-tui.json"
echo "Scripts -> $CFG/{cmux-stats,gpu-stats,cmux-workspaces}.sh"

# 4. Workspace spec (never overwritten)
if [ ! -f "$CFG/workspaces.conf" ]; then
    cp "$SRC/workspaces.conf.example" "$CFG/workspaces.conf"
    echo "Example workspace spec -> $CFG/workspaces.conf (edit me)"
fi

# 5. Reload a running default session, if any
if cmux server status --session main 2>/dev/null | grep -q running; then
    cmux server reload-config --session main >/dev/null 2>&1 && echo "Reloaded config in running session 'main'"
fi

echo ""
echo "=== DONE ==="
echo ""
echo "Next steps:"
echo "  1. cmux                              — start / attach (session survives detaching)"
echo "  2. $CFG/cmux-workspaces.sh up        — build workspaces from workspaces.conf"
echo ""
echo "Keybindings (prefix = C-a):"
echo "  prefix + -  /  |     split down / right"
echo "  prefix + z  /  +     zoom pane"
echo "  prefix + x  /  X     close pane / tab"
echo "  prefix + c           new screen (tmux window)    prefix + W  new workspace (tmux session)"
echo "  prefix + C-h / C-l   previous / next screen"
echo "  Alt+arrows           pane navigation             Alt+= / Alt+-  resize"
echo "  prefix + ?           full shortcut list          prefix + d  detach"
echo ""
echo "GPU auto-detect: $("$CFG/gpu-stats.sh" 2>/dev/null || echo 'no GPU found')"
