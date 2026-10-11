# Elemental effects and themes for Speshell. `just --list` shows every recipe.

qt6_bin := shell('for d in /usr/lib/qt6/bin /usr/lib64/qt6/bin; do [ -d "$d" ] && echo "$d" && break; done; true')
qsb := env("QSB", if qt6_bin != "" { qt6_bin / "qsb" } else { "qsb" })
effects_dir := env("XDG_DATA_HOME", env("HOME") / ".local/share") / "speshell/effects"
themes_dir := env("XDG_CONFIG_HOME", env("HOME") / ".config") / "speshell/themes"

# Speshell checkout or install whose WallpaperView hosts the wallpaper scene.
export SPESHELL_DIR := env("SPESHELL_DIR", shell('for d in ../speshell /usr/share/speshell; do [ -d "$d" ] && realpath "$d" && break; done; true'))

[private]
default:
    @just --list

# Compile the shaders that changed.
shaders:
    #!/bin/sh
    set -e
    for frag in effects/*/shaders/*.frag backgrounds/*.frag; do
        out="$frag.qsb"
        if [ ! -f "$out" ] || [ "$frag" -nt "$out" ] || [ lib/common.glsl -nt "$out" ] \
                || [ backgrounds/landscape.glsl -nt "$out" ]; then
            echo "qsb $frag"
            {{ qsb }} --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$out" "$frag"
        fi
    done

# Symlink every effect into Speshell's effects directory.
link: shaders
    mkdir -p "{{ effects_dir }}"
    for dir in effects/*/; do ln -sfn "$PWD/$dir" "{{ effects_dir }}/$(basename "$dir")"; done

# Copy the nation themes and their wallpapers into Speshell's themes directory, keeping existing files.
themes:
    for dir in themes/*/; do mkdir -p "{{ themes_dir }}/$(basename "$dir")" \
        && cp -n "$dir"* "{{ themes_dir }}/$(basename "$dir")/"; done

# Re-render each theme's default wallpaper from its painting in backgrounds/ (needs a Wayland session).
backgrounds: shaders
    lab/background.sh ember-dusk themes/fire-nation/ember-dusk.jpg
    lab/background.sh cloud-sea themes/air-nomads/cloud-sea.jpg
    lab/background.sh polar-night themes/water-tribe/polar-night.jpg
    lab/background.sh golden-mesas themes/earth-kingdom/golden-mesas.jpg

# Render an effect's scene offscreen into lab/out/<effect>-<scene>.mp4 (needs a Wayland session).
preview effect="fire" scene="launcher": shaders
    lab/preview.sh "{{ effect }}" "{{ scene }}"

# Render every effect and scene; fail on QML errors, warnings, or a transition that never finishes.
check: shaders
    lab/check.sh $(ls effects)

# Estimate an effect scene's GPU time per frame at 1080p (needs a Wayland session).
perf effect="fire" scene="launcher": shaders
    lab/perf.sh "{{ effect }}" "{{ scene }}"

# Remove compiled shaders and lab output.
clean:
    rm -f effects/*/shaders/*.qsb backgrounds/*.qsb
    rm -rf lab/out
