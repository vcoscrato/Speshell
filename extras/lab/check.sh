#!/bin/sh
# usage: lab/check.sh EFFECT...  Renders each effect's scenes and checks their logs, and
# that the dashboard entrance's last frame shows the panel exactly as it is, so the
# panel does not jump when the entrance goes.
LAB=$(cd "$(dirname "$0")" && pwd)
LAB_OUT=${LAB_OUT:-${XDG_CACHE_HOME:-$HOME/.cache}/speshell-lab}
status=0
# Pixels of the panel that change between the entrance's last frame and the panel once
# it has gone, if any do.
jump() {
    frames="$LAB_OUT/$1-dashboard"
    t=$(grep -oE 'finished at [0-9.]+' "$LAB_OUT/$1-dashboard.log" | grep -oE '[0-9.]+$')
    [ -n "$t" ] || return 0
    last=$(printf '%s/%04d.bmp' "$frames" "$(awk -v t="$t" 'BEGIN { print int(t * 60 + 0.5) - 1 }')")
    final=$(ls "$frames"/*.bmp | tail -1)
    n=$(magick compare -metric AE -fuzz 2% "$last[420x1048+16+16]" "$final[420x1048+16+16]" null: 2>&1 | grep -oE '^[0-9.]+')
    awk -v n="$n" 'BEGIN { exit !(n > 20) }' && echo "$n"
}
for effect in "$@"; do
    for scene in launcher wallpaper dashboard controls; do
        if [ "$scene" = dashboard ]; then
            EVERY_FRAME=1 KEEP_FRAMES=1 "$LAB/preview.sh" "$effect" "$scene" >/dev/null 2>&1
        else
            "$LAB/preview.sh" "$effect" "$scene" >/dev/null 2>&1
        fi
        log="$LAB_OUT/$effect-$scene.log"
        problems=$(grep -E "rror|WARN" "$log" | grep -v "window masks")
        if [ -n "$problems" ]; then
            printf 'FAIL %s %s:\n%s\n' "$effect" "$scene" "$problems"
            status=1
        elif [ "$scene" = dashboard ] && [ -n "$(jump "$effect")" ]; then
            printf 'FAIL %s %s: the panel jumps when the entrance goes (%s px change)\n' "$effect" "$scene" "$(jump "$effect")"
            status=1
        elif [ "$scene" != controls ] && ! grep -qE "closingFinished|transition finished|no dashboard transition" "$log"; then
            printf 'FAIL %s %s: the transition never finished\n' "$effect" "$scene"
            status=1
        elif [ "$scene" = controls ]; then
            printf 'ok   %s %s\n' "$effect" "$scene"
        else
            printf 'ok   %s %s, finished at %ss\n' "$effect" "$scene" \
                "$(grep -oE '(closingFinished|finished) at [0-9.]+' "$log" | tail -1 | grep -oE '[0-9.]+$')"
        fi
        rm -rf "$LAB_OUT/$effect-dashboard"
    done
done
exit $status
