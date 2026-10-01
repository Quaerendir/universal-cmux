#!/bin/sh
# cmux-stats.sh — CPU / RAM / load segments for the cmux status bar
# Usage: cmux-stats.sh cpu|ram|load
# Linux (/proc). Prints nothing on platforms without /proc, so the segment stays empty.

case "$1" in
cpu)
    [ -r /proc/stat ] || exit 0
    read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat
    sleep 1
    read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
    idle=$(( (i2 + w2) - (i1 + w1) ))
    total=$(( (u2+n2+s2+i2+w2+q2+sq2) - (u1+n1+s1+i1+w1+q1+sq1) ))
    [ "$total" -gt 0 ] || exit 0
    printf 'CPU:%d%%\n' $(( (100 * (total - idle)) / total ))
    ;;
ram)
    [ -r /proc/meminfo ] || exit 0
    awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{if(t>0) printf "RAM:%.1f%%\n", (t-a)*100/t}' /proc/meminfo
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
