#!/bin/sh
# usage: lab/preview.sh SKIN SCENE  (SCENE: launcher | wallpaper)
# Renders offscreen into lab/out/SKIN-SCENE.mp4 and SKIN-SCENE-strip.png, and prints
# the transition's lifecycle log. Env: CLOSE_AT, SWITCH_AT, WALL_A, WALL_B, SPESHELL_DIR.
set -e
LAB=$(cd "$(dirname "$0")" && pwd)
SKIN=$1
SCENE=${2:-launcher}
NAME="$SKIN-$SCENE"
OUT="$LAB/out/$NAME"
SAMPLES="$LAB/out/samples"

# Stand-in wallpapers: procedural, so no artwork lives in the repository.
if [ ! -f "$SAMPLES/a.jpg" ]; then
    mkdir -p "$SAMPLES"
    for spec in "a 11 #34507c #101828" "b 23 #d9b98a #4d6f6a"; do
        set -- $spec
        magick -size 1920x1080 gradient:"$3-$4" \( -size 480x270 -seed "$2" plasma:fractal -colorspace gray \
            -auto-level -resize 1920x1080! -blur 0x24 +level 30%,70% \) -compose overlay -composite "$SAMPLES/$1.jpg"
    done
fi
WALL_A=${WALL_A:-$SAMPLES/a.jpg}
WALL_B=${WALL_B:-$SAMPLES/b.jpg}
SPESHELL_DIR=${SPESHELL_DIR:-/usr/share/speshell}

case "$SCENE" in
    launcher) END=$(awk -v c="${CLOSE_AT:-2.2}" 'BEGIN { print c + 1.2 }'); CROP="crop=1100:760:410:20," ;;
    wallpaper) END=$(awk -v s="${SWITCH_AT:-0.3}" 'BEGIN { print s + 2.8 }'); CROP="scale=1280:720," ;;
    *) echo "unknown scene: $SCENE" >&2; exit 2 ;;
esac

rm -rf "$OUT" && mkdir -p "$OUT"
LOG="$LAB/out/$NAME.log"
SKIN_DIR="$LAB/../skins/$SKIN" SCENE="$LAB/$(echo "$SCENE" | sed 's/./\U&/')Scene.qml" \
    DURATION="$END" OUT="$OUT" WALL_A="$WALL_A" WALL_B="$WALL_B" SPESHELL_DIR="$SPESHELL_DIR" \
    QT_FORCE_STDERR_LOGGING=1 timeout 90 quickshell --no-color -p "$LAB/shell.qml" >"$LOG" 2>&1 || true
grep -E "closingFinished|transition|ERROR|rror:|WARN" "$LOG" | grep -v "window masks" || true

ffmpeg -loglevel error -y -framerate 30 -i "$OUT/%04d.bmp" -vf "${CROP}format=yuv420p" \
    -c:v libx264 -crf 18 "$LAB/out/$NAME.mp4"
# Contact strip at fixed moments (seconds) of each scene.
case "$SCENE" in
    launcher) TIMES="0.25 0.5 1.2 $(awk -v c="${CLOSE_AT:-2.2}" 'BEGIN { print c + 0.15, c + 0.35 }')"
        TILE="-crop 1100x760+410+20 +repage -resize 30%" ;;
    wallpaper) TIMES=$(awk -v s="${SWITCH_AT:-0.3}" 'BEGIN { print s + 0.3, s + 0.6, s + 1, s + 1.4, s + 1.9 }')
        TILE="-resize 18%" ;;
esac
magick $(for t in $TIMES; do printf '%s/%04d.bmp ' "$OUT" "$(awk -v t="$t" 'BEGIN { print int(t * 30 + 0.5) }')"; done) \
    $TILE +append "$LAB/out/$NAME-strip.png"
echo "$LAB/out/$NAME.mp4"
