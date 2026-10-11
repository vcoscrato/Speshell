# Themes and effects

The themes and effects Speshell ships, the paintings behind their wallpapers, and the lab used to build and check them. Everything here is original work.

| Theme | Effects | Wallpaper (painting) | Launcher | Wallpaper change |
|---|---|---|---|---|
| Cosmos (default) | `cosmos` | `spiral-galaxy` | Opens out of a flaring star; planets orbit it while open | Supernova |
| Fire | `fire` | `ember-dusk` | Burns in behind an ember's edge; flames simmer around it | Burns away from the middle |
| Air | `air` | `cloud-sea` | Unwinds out of a whirlwind; a breeze with leaves circles it | Whirlwind eye |
| Water | `water` | `polar-night` | A water whip coils into it and clears through rippling caustics; two streams chase its border among orbs, currents, and mist held in the air | Ripple |
| Earth | `earth` | `jade-valley` | Punches up out of cracked ground as a stone slab; tumbling boulders with circling pebbles hover in a ring of dust and stones | Cracks and crumbles |

## Layout

| Path | Holds | Ships | Who edits it |
|---|---|---|---|
| `themes/<theme>/` | `theme.ini` (name, palette, `effects = <name>`) and the rendered wallpaper `<painting>.jpg` | yes | designers: palettes; artists: commit the wallpaper they render |
| `paintings/` | `<painting>.frag`, one shader per wallpaper, and `landscape.glsl`, the helpers they share | no | artists |
| `effects/<name>/` | Launcher and wallpaper transitions. See [effects/README.md](effects/README.md) | yes | effects developers |
| `lib/` | `common.glsl` (noise, signed distances, banding, Voronoi) and `EffectClock.qml`, shared by every effect | yes | effects developers; a change here touches every effect |
| `lab/` | The offscreen harness, scenes, and scripts behind the `just` recipes; output goes to the git-ignored `lab/out/` | no | anyone improving the tooling |

The package installs `themes/`, `effects/`, and `lib/` to `/usr/share/speshell/extras`. Nothing else in this directory ships. Keep sources and tools out of those three directories.

Names are lowercase-kebab for directories, paintings, and shaders; QML components are PascalCase. A theme and an effect are named for their element (`fire`), and a painting for its scene (`ember-dusk`). Any theme can use any effects.

## Rules

- **Original work only.** No fan art, photos, fonts, or code under another license. Wallpapers come from shaders in `paintings/`, so their whole source is in the repository.
- **A wallpaper is committed with its painting.** After editing `paintings/<painting>.frag`, run `just paint <painting>` and commit the `.jpg` in the same change.
- **`just check` passes** before effects changes are merged. It fails on any QML error or warning, or a transition that never finishes.
- **Stay within the GPU budget:** under 0.5 ms per frame at 1080p in every phase (`just perf`). The current costs are in [effects/README.md](effects/README.md#cost).
- **Compiled shaders (`*.qsb`) are build output.** They're git-ignored; `just shaders` makes them, and the package build runs it.

## Workflows

Run every recipe from the repository root. The lab renders through an invisible 1×1 overlay, so it needs a Wayland session, plus `qt6-shadertools`, ffmpeg, and ImageMagick.

**Retune a theme's palette.** Edit `themes/<theme>/theme.ini`. Its keys are listed in `themes/cosmos/theme.ini`; missing ones fall back to Cosmos. Pick the theme in Speshell's Themes panel to see it.

**Paint a wallpaper.**

```bash
just paint ember-dusk                    # renders paintings/ember-dusk.frag over themes/fire/ember-dusk.jpg
WIDTH=1920 HEIGHT=1080 just paint ember-dusk   # quicker draft while iterating
just paint                               # re-render every wallpaper that has a painting
```

A painting renders over each `themes/*/<painting>.jpg` of the same name. A new painting with no wallpaper yet lands in `lab/out/<painting>.jpg`; copy it into its theme folder once. Start a new painting from an existing one: it shows the uniform block, the `common.glsl` and `landscape.glsl` includes, and the header comment that describes the scene.

**Add a theme.** Create `themes/<theme>/` with a `theme.ini` and a wallpaper, usually from a new painting. Add it to the table above.

**Build or change effects.** Copy the closest effect directory (with its `common` symlink, made with `ln -s ../../lib common`) and follow [effects/README.md](effects/README.md). Then iterate:

```bash
just preview fire launcher               # lab/out/fire-launcher.mp4 and a contact strip
just preview water wallpaper
just check                               # every effect and scene
just perf fire launcher                  # GPU time per frame at 1080p
```

Scenes drive `EffectClock` with virtual time, 1/60 s per frame, so captures match real playback. The wallpaper scene hosts this checkout's `core/WallpaperView.qml`. Env knobs:

- `WALL_A` and `WALL_B`: your own wallpapers.
- `CLOSE_AT`, `REOPEN_AT`, `SWITCH_AT`, and `SPEED` for the scenes.
- `KEEP_FRAMES=1` keeps the frames, about 700 MB per run.
- For perf, `PERF_FROM` and `DURATION`. For example, `CLOSE_AT=30 PERF_FROM=1.5 DURATION=4.5 just perf air` measures only the open launcher.

`just clean` removes compiled shaders and all lab output.

**Try it in the real shell.** Quickshell reloads QML when its files change, but Qt keeps every shader it has loaded until the process exits. Restart Speshell after a shader change, or run `just local-package-install`, which restarts it.
