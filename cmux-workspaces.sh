#!/bin/bash
# cmux-workspaces.sh — recreate named workspaces/splits from a plain-text spec
# (the cmux counterpart of a hand-rolled tmux session script).
#
# Usage: cmux-workspaces.sh [-s session] [-f spec-file] [up|list]
#   up    create every workspace from the spec that does not exist yet (default)
#   list  show what the spec would create
#
# Spec format (one directive per line, # comments):
#   workspace NAME DIR [COMMAND...]   new workspace (quote NAME if it has spaces); first pane cd's to DIR, runs COMMAND
#   split right|down [COMMAND...]     split the last pane of the current workspace
#
# Idempotent: workspaces whose name already exists in the session are skipped.
# cmux persists layout itself; this only (re)builds it from scratch, e.g. on a new box.

set -u
SESSION=main
SPEC="${XDG_CONFIG_HOME:-$HOME/.config}/cmux/workspaces.conf"

while getopts "s:f:h" opt; do
    case $opt in
        s) SESSION=$OPTARG ;;
        f) SPEC=$OPTARG ;;
        *) sed -n '2,15p' "$0"; exit 0 ;;
    esac
done
shift $((OPTIND - 1))
ACTION=${1:-up}

command -v cmux >/dev/null || { echo "cmux not found (npm install -g cmux)" >&2; exit 1; }
[ -r "$SPEC" ] || { echo "spec not found: $SPEC" >&2; exit 1; }

c() { cmux --session "$SESSION" "$@"; }
# value of a "key   value" line from cmux text output
field() { awk -v k="$1" '$1 == k { print $2; exit }'; }

existing=""
if [ "$ACTION" = up ]; then
    cmux server ensure --session "$SESSION" >/dev/null || exit 1
    # columns: ID NAME INDEX FOCUSED SESSION (NAME may contain spaces)
    existing=$(c workspace list | sed -E '1d; s/^[^ ]+ +//; s/ +[0-9]+ +(true|false) +[^ ]+$//')
fi

skip=0
pane="" term="" dir=""
while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    [ -n "${line//[[:space:]]/}" ] || continue
    set -f; eval "w=($line)" 2>/dev/null || { set +f; echo "bad line: $line" >&2; continue; }; set +f  # quotes allowed in names
    case "${w[0]}" in
    workspace)
        name=${w[1]:?workspace needs a NAME}
        dir=${w[2]:?workspace needs a DIR}
        dir=${dir/#\~/$HOME}
        cmd="${w[*]:3}"
        if [ "$ACTION" = list ]; then echo "workspace $name  $dir  $cmd"; continue; fi
        if grep -qx -- "$name" <<< "$existing"; then
            echo "skip: workspace '$name' exists"; skip=1; continue
        fi
        skip=0
        out=$(c workspace create --name "$name") || { echo "failed: $name" >&2; skip=1; continue; }
        pane=$(field value.pane_id <<< "$out"); term=$(field value.terminal_id <<< "$out")
        c terminal "$term" write --text "cd \"$dir\" && clear${cmd:+; $cmd}"$'\n' >/dev/null
        echo "created: $name"
        ;;
    split)
        if [ "$ACTION" = list ]; then echo "  split ${w[*]:1}"; continue; fi
        [ "$skip" = 1 ] && continue
        dirn=${w[1]:?split needs right|down}
        cmd="${w[*]:2}"
        out=$(c pane "$pane" split "--$dirn") || { echo "split failed" >&2; continue; }
        pane=$(field value.pane_id <<< "$out"); term=$(field value.terminal_id <<< "$out")
        c terminal "$term" write --text "cd \"$dir\" && clear${cmd:+; $cmd}"$'\n' >/dev/null
        ;;
    *)
        echo "unknown directive: ${w[0]}" >&2
        ;;
    esac
done < "$SPEC"
