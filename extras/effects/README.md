# Effects

An effects directory animates the launcher and wallpaper changes for any theme that names it with `effects = <name>` in its `theme.ini`. Speshell looks in `extras/effects` and `~/.local/share/speshell/effects`; a user directory replaces a shipped one of the same name. If effects fail to load, Speshell notifies and runs without them.

Every effect here has the same files:

```
<name>/
├── Effects.qml               entry point: API version and the two transitions
├── LauncherTransition.qml    the launcher opening, staying open, and closing
├── WallpaperTransition.qml   the change from one wallpaper to the next
├── <Part>.qml                pieces the transitions use (Flames, Wind, Whip, ...)
├── shaders/*.frag            GLSL sources; `just shaders` compiles them to git-ignored .qsb files
└── common -> ../../lib       symlink that gives QML `import "common"` (EffectClock)
```

Shaders include the shared library by relative path: `#include "../../../lib/common.glsl"`.

## API

`Effects.qml` declares API version 1. Both transitions are optional:

```qml
import QtQuick

QtObject {
    readonly property int apiVersion: 1
    readonly property Component launcherTransition: Component { LauncherTransition {} }
    readonly property Component wallpaperTransition: Component { WallpaperTransition {} }
}
```

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

Speshell destroys a transition inside its finishing signal, so nothing may run after the emit. Take time from `EffectClock`, which ticks at about 60 Hz, never from your own timers or `Date`. It follows the user's transition speed (`[Appearance] transitionSpeed`, exposed as `timeScale`), so its `clock`, `simTime`, and `dt` already run fast or slow; a simulation that steps once per frame should scale its step by `timeScale`. With transitions off, Speshell does not create them.

## Style

Effects draw in flat, anti-aliased color bands for a cel-shaded look, and shape the captured panel or outgoing wallpaper with a second shader. Ambient animation while the launcher is open stays outside the panel or is masked from it. Air sets the bar for polish: layered depth, small secondary particles, and organic randomness rather than regular, repeated shapes.

## How each works

- **Cosmos** draws its solar system analytically in one shader: tilted orbits, cel-shaded planets, a ringed giant, a moon that passes behind its planet. A lens-edged portal reveals the panel and the old wallpaper.
- **Fire** runs a quarter-resolution fluid simulation at a fixed 60 Hz step through a recursive `ShaderEffectSource`.
- **Air** draws streaks along the stream function of an ideal 2D flow (breeze around an ellipse, vortex, source or sink) bent by curl noise, so they never cross. Leaves and dust ride analytic orbits.
- **Water** draws tubes along a spiral and along the panel's rounded border, modulated by waves from each head, with drag-and-gravity droplets. The sheet and ripple refract the captured images; the sheet's caustics are warped Voronoi edges. Orbs, currents, and mist travel along the border pushed outward, so they never cross the panel.
- **Earth** builds stone, cracks, and shards from Voronoi cells, and boulders from faceted polygons whose faces are shaded by their turning normals as they tumble.

## Cost

GPU time per frame at 1080p on an RTX 3070 (`just perf`):

| Effects | Launcher open | Launcher entrance and exit | Wallpaper |
|---|---|---|---|
| Cosmos | 0.09 ms | 0.09 ms | 0.01 ms |
| Fire | 0.33 ms | 0.29 ms | 0.20 ms |
| Air | 0.19 ms | 0.26 ms | 0.26 ms |
| Water | 0.41 ms | 0.31 ms | under 0.07 ms |
| Earth | 0.39 ms | 0.48 ms | 0.23 ms |

Nothing runs while the launcher is hidden and the wallpaper is still. Re-measure after a change and update this table.
