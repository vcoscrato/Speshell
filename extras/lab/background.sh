#!/bin/sh
# usage: lab/background.sh NAME OUT  Renders backgrounds/NAME.frag offscreen at
# WIDTH x HEIGHT (default 3840x2160) and saves it as OUT (.jpg or .png).
set -e
LAB=$(cd "$(dirname "$0")" && pwd)
FRAMES=$(mktemp -d)
trap 'rm -rf "$FRAMES"' EXIT
SCENE="$LAB/BackgroundScene.qml" BACKGROUND="$LAB/../backgrounds/$1.frag.qsb" DURATION=0.05 OUT="$FRAMES" \
    QT_FORCE_STDERR_LOGGING=1 timeout 60 quickshell --no-color -p "$LAB/shell.qml" 2>&1 \
    | grep -E "rror|WARN" | grep -v "window masks" >&2 || true
[ -f "$FRAMES/0001.bmp" ] || { echo "background.sh: $1 did not render" >&2; exit 1; }
magick "$FRAMES/0001.bmp" -quality 92 "$2"
