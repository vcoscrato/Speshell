#!/bin/sh
# usage: lab/perf.sh SKIN SCENE  Estimates GPU time per frame of one full-resolution
# instance from the slope between 1 and COPIES instances rendered every frame,
# doubling COPIES until the frame time clearly rises above vsync. Env: PERF_FROM
# measures from that many seconds in, DURATION ends the run (default 2.5).
LAB=$(cd "$(dirname "$0")" && pwd)
SKIN=$1
SCENE=${2:-launcher}
COPIES=${COPIES:-24}
SAMPLES="$LAB/out/samples"
[ -f "$SAMPLES/a.jpg" ] || { echo "run make preview first to create sample wallpapers" >&2; exit 1; }
INNER="$LAB/$(echo "$SCENE" | sed 's/./\U&/')Scene.qml"
measure() {
    SKIN_DIR="$LAB/../skins/$SKIN" SCENE="$LAB/PerfScene.qml" INNER="$INNER" COPIES="$1" PERF=1 \
        DURATION="${DURATION:-2.5}" OUT=/dev/null WALL_A="$SAMPLES/a.jpg" WALL_B="$SAMPLES/b.jpg" \
        SPESHELL_DIR="${SPESHELL_DIR:-/usr/share/speshell}" QT_FORCE_STDERR_LOGGING=1 \
        timeout 120 quickshell --no-color -p "$LAB/shell.qml" 2>&1 | grep -oE "perf: [0-9.]+" | grep -oE "[0-9.]+$"
}
ONE=$(measure 1)
# Cheap effects hide under vsync; add copies until the frame time clearly rises.
while :; do
    MANY=$(measure "$COPIES")
    if awk -v one="$ONE" -v many="$MANY" -v n="$COPIES" 'BEGIN { exit !(many > one * 2 || n >= 96) }'; then
        break
    fi
    COPIES=$((COPIES * 2))
done
awk -v one="$ONE" -v many="$MANY" -v n="$COPIES" -v s="$SKIN" -v sc="$SCENE" 'BEGIN {
    printf "%s %s: %.3f ms/frame with 1 copy, %.3f with %d; about %.2f ms GPU per instance per frame\n",
        s, sc, one, many, n, (many - one) / (n - 1) }'
