# Prefer Qt 6 tools; on Arch, /usr/bin/qmllint may belong to Qt 5.
qt6_bin := shell('for d in /usr/lib/qt6/bin /usr/lib64/qt6/bin; do [ -d "$d" ] && echo "$d" && break; done; true')
qmllint := env("QMLLINT", if qt6_bin != "" { qt6_bin / "qmllint" } else { "qmllint" })
qmltestrunner := env("QMLTESTRUNNER", if qt6_bin != "" { qt6_bin / "qmltestrunner" } else { "qmltestrunner" })
qsb := env("QSB", if qt6_bin != "" { qt6_bin / "qsb" } else { "qsb" })

# The effects lab hosts this checkout's WallpaperView.
export SPESHELL_DIR := justfile_directory()

[private]
default:
    @just --list

# Lint every QML module; any warning fails.
lint:
    #!/bin/sh
    # qmllint 6.12 reports some singletons as missing from services/qmldir even
    # though they are declared there, and the warning can't be disabled in-file.
    out=$({{ qmllint }} shell.qml core/*.qml components/*.qml services/*.qml theme/*.qml widgets/*.qml 2>&1 \
        | grep -v 'not declared as singleton in qmldir but using pragma Singleton')
    [ -z "$out" ] || { printf '%s\n' "$out"; exit 1; }

# Run the QML unit tests.
test:
    QT_QPA_PLATFORM=offscreen {{ qmltestrunner }} -input tests

# Compile the effect and painting shaders that changed.
[working-directory: 'extras']
shaders:
    #!/bin/sh
    set -e
    for frag in effects/*/shaders/*.frag paintings/*.frag; do
        out="$frag.qsb"
        if [ ! -f "$out" ] || [ "$frag" -nt "$out" ] || [ lib/common.glsl -nt "$out" ] \
                || [ paintings/landscape.glsl -nt "$out" ]; then
            echo "qsb $frag"
            {{ qsb }} --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$out" "$frag"
        fi
    done

# Render paintings/<name>.frag over each themes/*/<name>.jpg (else extras/lab/out/); no name: all (needs Wayland).
[working-directory: 'extras']
paint name="": shaders
    #!/bin/sh
    set -e
    name="{{ name }}"
    for frag in paintings/${name:-*}.frag; do
        [ -f "$frag" ] || { echo "no painting $frag" >&2; exit 1; }
        painting=$(basename "$frag" .frag)
        targets=$(ls themes/*/"$painting.jpg" 2>/dev/null || true)
        [ -n "$targets" ] || [ -z "$name" ] || targets="lab/out/$painting.jpg"
        for out in $targets; do
            echo "paint $painting -> $out"
            lab/paint.sh "$painting" "$out"
        done
    done

# Render an effect's scene offscreen into extras/lab/out/<effect>-<scene>.mp4 (needs a Wayland session).
[working-directory: 'extras']
preview effect="cosmos" scene="launcher": shaders
    lab/preview.sh "{{ effect }}" "{{ scene }}"

# Render every effect and scene; fail on QML errors, warnings, or a transition that never finishes.
[working-directory: 'extras']
check: shaders
    lab/check.sh $(cd effects && ls -d */ | tr -d /)

# Estimate an effect scene's GPU time per frame at 1080p (needs a Wayland session).
[working-directory: 'extras']
perf effect="cosmos" scene="launcher": shaders
    lab/perf.sh "{{ effect }}" "{{ scene }}"

# Remove compiled shaders and lab output.
[working-directory: 'extras']
clean:
    rm -f effects/*/shaders/*.qsb paintings/*.qsb
    rm -rf lab/out

# Build and install a package from this checkout, uncommitted changes included.
local-package-install:
    #!/bin/sh
    set -e
    builddir=$(mktemp -d /tmp/speshell-local.XXXXXX)
    printf 'Building local package in %s\n' "$builddir"
    mkdir -p "$builddir/src/speshell"
    cp PKGBUILD "$builddir/"
    tar --exclude='./src' --exclude='./pkg' --exclude='./speshell' --exclude='./*.pkg.tar.*' \
        --exclude='./extras/lab/out' \
        -cf - . | tar -C "$builddir/src/speshell" -xf -
    (cd "$builddir" && makepkg -efsi)
    echo "Installed. Restart Speshell to load new shaders."
