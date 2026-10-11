# Themes and effects

The themes and effects Speshell ships, plus the lab used to build them. Everything here is original work, including the wallpapers, which `backgrounds/` renders.

| Theme | Effects | Launcher | Wallpaper change |
|---|---|---|---|
| Cosmos (default) | `cosmos` | Opens out of a flaring star; planets orbit it while open | Supernova |
| Fire Nation | `fire` | Burns in behind an ember's edge; flames simmer around it | Burns away from the middle |
| Air Nomads | `air` | Unwinds out of a whirlwind; a breeze with leaves circles it | Whirlwind eye |
| Water Tribe | `water` | A water whip coils into it; two streams chase its border | Ripple |
| Earth Kingdom | `earth` | Punches up out of cracked ground as a stone slab; boulders hover around it | Cracks and crumbles |

Any theme can use these with `effects = <name>` in its `theme.ini`.

## Effects API

An effects directory holds an `Effects.qml` that declares API version 1. Both transitions are optional:

```qml
import QtQuick

QtObject {
    readonly property int apiVersion: 1
    readonly property Component launcherTransition: Component { MyLauncherTransition {} }
    readonly property Component wallpaperTransition: Component { MyWallpaperTransition {} }
}
```

Speshell looks in `extras/effects` and `~/.local/share/speshell/effects`; a user directory replaces a shipped one of the same name. If effects fail to load, Speshell notifies and runs without them.

**Launcher transition.** Created when the launcher opens and destroyed after it hides. It fills the launcher's full-screen surface above the panel and receives:

| Property | Meaning |
|---|---|
| `panel` | The launcher panel. Capture it with a `ShaderEffectSource` (`hideSource: true`) to draw it yourself. |
| `panelRect` | The panel's geometry. It changes as the result list grows or shrinks. |
| `active` | `false` once the launcher closes; `true` again if it reopens during the exit. |

Emit `closingFinished()` when the exit is done; Speshell hides the launcher anyway after 2.5 s. Input is ignored during the exit.

**Wallpaper transition.** Created once the new wallpaper has loaded, filling the screen above both images:

| Property | Meaning |
|---|---|
| `outgoing` | The old image, on top. Hide it (`hideSource: true`) and draw it going away. |
| `incoming` | The new image, already showing beneath. |

Emit `finished()` when done; Speshell removes it after 5 s otherwise. Without a wallpaper transition the old image fades out.

Speshell destroys a transition inside its finishing signal, so nothing may run after the emit. Take time from `EffectClock` (in `lib/`), which ticks at about 60 Hz, never from your own timers or `Date`.

## How it works

Effects draw in flat, anti-aliased color bands for a cel-shaded look, and shape the captured panel or outgoing wallpaper with a second shader.

- **Cosmos** draws its solar system analytically in one shader: tilted orbits, cel-shaded planets, a ringed giant, a moon that passes behind its planet. A lens-edged portal reveals the panel and the old wallpaper.
- **Fire** runs a quarter-resolution fluid simulation at a fixed 60 Hz step through a recursive `ShaderEffectSource`.
- **Air** draws streaks along the stream function of an ideal 2D flow (breeze around an ellipse, vortex, source or sink) bent by curl noise, so they never cross. Leaves and dust ride analytic orbits.
- **Water** draws tubes along a spiral and along the panel's rounded border, modulated by waves from each head, with drag-and-gravity droplets. The sheet and ripple refract the captured images.
- **Earth** builds stone, cracks, and shards from Voronoi cells, and boulders from faceted polygons.

GPU time per frame at 1080p on an RTX 3070 (`just perf`):

| Effects | Launcher open | Launcher entrance and exit | Wallpaper |
|---|---|---|---|
| Cosmos | 0.09 ms | 0.09 ms | 0.01 ms |
| Fire | 0.33 ms | 0.29 ms | 0.20 ms |
| Air | 0.19 ms | 0.26 ms | 0.26 ms |
| Water | 0.19 ms | 0.15 ms | under 0.07 ms |
| Earth | 0.10 ms | 0.18 ms | 0.23 ms |

Nothing runs while the launcher is hidden and the wallpaper is still.

## Lab

The lab renders effects offscreen through an invisible 1×1 overlay, so it needs a Wayland session, plus `qt6-shadertools`, ffmpeg, and ImageMagick. Run from the repository root:

```bash
just preview fire launcher   # extras/lab/out/fire-launcher.mp4 and a contact strip
just preview water wallpaper
just check                   # every effect and scene; fails on warnings
just perf fire launcher      # GPU time per frame at 1080p
just backgrounds             # re-render the default wallpapers
```

Scenes drive `EffectClock` with virtual time, 1/60 s per frame, so captures match real playback. The wallpaper scene hosts this checkout's `core/WallpaperView.qml`. Env knobs: `WALL_A`/`WALL_B` (your own wallpapers), `CLOSE_AT`, `SWITCH_AT`, and for perf `PERF_FROM`/`DURATION`, e.g. `CLOSE_AT=30 PERF_FROM=1.5 DURATION=4.5 just perf air` to measure only the open launcher.

Qt caches compiled QML, so a running Speshell needs a restart to pick up effect edits; shader edits also need `just shaders`.

Layout:

- `lib/`: `common.glsl` (noise, curl, signed distances, banding, Voronoi, rounded-rect arcs) and `EffectClock.qml`.
- `effects/<name>/`: `Effects.qml`, its components, a `common -> ../../lib` symlink, and `shaders/*.frag`.
- `themes/<id>/`: `theme.ini` and the default wallpaper.
- `backgrounds/`: the shaders that paint the default wallpapers.
- `lab/`: the harness, scenes, and scripts.

To add effects, create `effects/<name>/` with the `common` symlink and an `Effects.qml`, iterate with `just preview <name>`, and finish with `just check`.
