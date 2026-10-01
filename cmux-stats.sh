#!/bin/sh
# cmux-stats.sh — CPU / RAM / load segments for the cmux status bar
# Usage: cmux-stats.sh cpu|ram|load
# Linux (/proc) and macOS (top / vm_stat). Prints nothing on other platforms,
# so the segment stays empty instead of showing an error.

case "$1" in
cpu)
    if [ -r /proc/stat ]; then
        read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat
        sleep 1
        read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
        idle=$(( (i2 + w2) - (i1 + w1) ))
        total=$(( (u2+n2+s2+i2+w2+q2+sq2) - (u1+n1+s1+i1+w1+q1+sq1) ))
        [ "$total" -gt 0 ] || exit 0
        printf 'CPU:%d%%\n' $(( (100 * (total - idle)) / total ))
    elif [ "$(uname)" = Darwin ]; then
        # 2nd sample = usage over the last second (1st is since boot)
        top -l 2 -n 0 -s 1 2>/dev/null | awk '/^CPU usage:/ {idle=$7} END{if (idle != "") printf "CPU:%d%%\n", 100 - idle + 0.5}'
    fi
    ;;
ram)
    if [ -r /proc/meminfo ]; then
        awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{if(t>0) printf "RAM:%.1f%%\n", (t-a)*100/t}' /proc/meminfo
    elif [ "$(uname)" = Darwin ]; then
        # "used" as Activity Monitor counts it: active + wired + compressed
        total=$(sysctl -n hw.memsize 2>/dev/null) || exit 0
        vm_stat 2>/dev/null | awk -v total="$total" '
            /page size of/ {ps=$8}
            /^Pages active:/ {a=$3}
            /^Pages wired down:/ {w=$4}
            /^Pages occupied by compressor:/ {c=$5}
            END{if (ps > 0 && total > 0) printf "RAM:%.1f%%\n", (a + w + c) * ps * 100 / total}'
    fi
    ;;
load)
    if [ -r /proc/loadavg ]; then
        cut -d' ' -f1-3 /proc/loadavg
    else
        sysctl -n vm.loadavg 2>/dev/null | tr -d '{}' | awk '{print $1, $2, $3}'
    fi
    ;;
*)
    echo "usage: $0 cpu|ram|load" >&2
    exit 1
    ;;
esac
