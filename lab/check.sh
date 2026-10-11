#!/bin/sh
# usage: lab/check.sh SKIN...  Renders each skin's scenes and checks their logs.
LAB=$(cd "$(dirname "$0")" && pwd)
status=0
for skin in "$@"; do
    for scene in launcher wallpaper; do
        "$LAB/preview.sh" "$skin" "$scene" >/dev/null 2>&1
        log="$LAB/out/$skin-$scene.log"
        problems=$(grep -E "rror|WARN" "$log" | grep -v "window masks")
        if [ -n "$problems" ]; then
            printf 'FAIL %s %s:\n%s\n' "$skin" "$scene" "$problems"
            status=1
        elif ! grep -qE "closingFinished|transition finished" "$log"; then
            printf 'FAIL %s %s: the transition never finished\n' "$skin" "$scene"
            status=1
        else
            printf 'ok   %s %s, finished at %ss\n' "$skin" "$scene" \
                "$(grep -oE '(closingFinished|finished) at [0-9.]+' "$log" | tail -1 | grep -oE '[0-9.]+$')"
        fi
    done
done
exit $status
