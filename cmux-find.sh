# cmux-find.sh — locate the cmux-tui binary (source this file, don't execute it)
#
# The name `cmux` is ambiguous: the npm package is the terminal multiplexer
# (cmux-tui), but inside the macOS cmux.app a different `cmux` (the GUI's CLI)
# is first in PATH. This picks the multiplexer, wherever it lives:
#   $CMUX_BIN, `cmux-tui` / `cmux` in PATH, npm global bin, the macOS app bundle.
# Usage: CMUX=$(find_cmux_tui) || echo "not found"

_cmux_is_tui() {
    [ -x "$1" ] && "$1" --help 2>&1 | grep -q 'terminal multiplexer'
}

find_cmux_tui() {
    if [ -n "${CMUX_BIN:-}" ] && _cmux_is_tui "$CMUX_BIN"; then
        echo "$CMUX_BIN"; return 0
    fi
    for _n in cmux-tui cmux; do
        _p=$(command -v "$_n" 2>/dev/null) || continue
        if _cmux_is_tui "$_p"; then echo "$_p"; return 0; fi
    done
    if command -v npm >/dev/null 2>&1; then
        _p="$(npm prefix -g 2>/dev/null)/bin/cmux"
        if _cmux_is_tui "$_p"; then echo "$_p"; return 0; fi
    fi
    for _p in /Applications/cmux.app/Contents/Resources/bin/cmux-tui \
              "$HOME/Applications/cmux.app/Contents/Resources/bin/cmux-tui"; do
        if _cmux_is_tui "$_p"; then echo "$_p"; return 0; fi
    done
    return 1
}
