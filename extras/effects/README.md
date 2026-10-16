# Effects

An effects directory animates the launcher, wallpaper changes, the dashboard's entrance, and the dashboard's controls, and paints the backdrop of the dashboard and launcher, for any theme that names it with `effects = <name>` in its `theme.ini`. Speshell looks in `extras/effects` and `~/.local/share/speshell/effects`; a user directory replaces a shipped one of the same name. If effects fail to load, Speshell notifies and runs without them.

Every effect here has these files; a part that draws with a shader another part shares has no `.frag` of its own. Each shader sits beside the QML that draws it, under the same name:

```
<name>/
├── Effects.qml                   entry point: API version, the transitions, and the backdrop
├── LauncherTransition.qml/.frag  the launcher opening, staying open, and closing
├── WallpaperTransition.qml/.frag the change from one wallpaper to the next
├── DashboardTransition.qml/.frag the dashboard's entrance
├── DashboardBackdrop.qml/.frag   the still painting behind the dashboard
├── Interactions.qml/.frag        the effects on the dashboard's controls
├── Knob.qml/.frag                the thumb of the dashboard's sliders and switches
├── <Part>.qml/.frag              pieces the transitions use (Flames, Wind, Whip, ...)
├── <Name>.js                     color recipes several parts share (Flame, Water, Stone, Bolt)
├── common -> ../../lib           symlink that gives QML `import "common"` (EffectClock, Particles) and `common/Colors.js`
└── qsb/                          git-ignored: `just shaders` compiles each `<Name>.frag` to `qsb/<Name>.qsb`
```

A QML file that draws more than one shader names the others `<Qml>.<piece>.frag` (`LauncherTransition.ground.frag`); a shader several parts share is named for what it draws (`Portal.frag`, `Burn.frag`). Shaders include the shared library by relative path: `#include "../../lib/common.glsl"`. A part loads its shader as `Qt.resolvedUrl("qsb/<Name>.qsb")`.

## API

`Effects.qml` declares API version 1. Every part is optional:

```qml
import QtQuick

QtObject {
    readonly property int apiVersion: 1
    readonly property Component launcherTransition: Component { LauncherTransition {} }
    readonly property Component wallpaperTransition: Component { WallpaperTransition {} }
    readonly property Component dashboardTransition: Component { DashboardTransition {} }
    readonly property Component dashboardBackdrop: Component { DashboardBackdrop {} }
    readonly property Component dashboardInteractions: Component { Interactions {} }
    readonly property Component knob: Component { Knob {} }
}
```

The dashboard parts arrived after the first two, still under version 1; an older Speshell ignores them.

**Colors.** Every part receives `theme`, the active palette as `Theme.qml` names it (`bg`, `crust`, `text`, `accent`, `peach`, `sky`, ...). Any theme may use any effects, so take every color from it, picking slots by meaning: fire from the warm colors, water from the blues, stone from the neutrals. Blend with `mix` and `alpha` from `common/Colors.js`, brighten with `Qt.lighter` where light burns brighter than any theme color (a flame's core, foam), and take a glint or sheen from `text`, the lightest color, never pure white. `theme` is null for a moment after creation, so each color falls back to a literal until it arrives: `root.theme ? root.theme.accent : "#fe8019"`. An older Speshell passes no `theme` to the launcher and wallpaper transitions, so they keep those fallbacks there.

**Launcher transition.** Created when the launcher opens and destroyed after it hides. It fills the launcher's full-screen surface above the panel and receives:

| Property | Meaning |
|---|---|
| `panel` | The launcher panel. Capture it with a `ShaderEffectSource` (`hideSource: true`) to draw it yourself. |
| `panelRect` | The panel's geometry. It changes as the result list grows or shrinks. |
| `active` | `false` once the launcher closes; `true` again if it reopens during the exit. |
| `theme` | The active palette. |

Emit `closingFinished()` when the exit is done; Speshell hides the launcher anyway after 2.5 s. Input is ignored during the exit.

**Wallpaper transition.** Created once the new wallpaper has loaded, filling the screen above both images:

| Property | Meaning |
|---|---|
| `outgoing` | The old image, on top. Hide it (`hideSource: true`) and draw it going away. |
| `incoming` | The new image, already showing beneath. |
| `theme` | The active palette, already the new wallpaper's theme. |

Emit `finished()` when done; Speshell removes it after 5 s otherwise. Without a wallpaper transition the old image fades out.

**Dashboard transition.** Created each time the dashboard appears and destroyed once it finishes, so nothing of it runs while the dashboard stays open. It fills the dashboard's own surface, which is exactly the panel, so it cannot draw outside it. The panel takes input meanwhile, so keep it short (under a second). The dashboard hides at once, with no exit.

| Property | Meaning |
|---|---|
| `panel` | The dashboard panel. Capture it with a `ShaderEffectSource` (`hideSource: true`) to draw it yourself. |
| `panelRect` | The panel's geometry, at the origin of the surface. |
| `theme` | The active palette. |

Emit `finished()` when done; Speshell removes it after 2.5 s otherwise. People open the dashboard to glance at the clock, so the entrance must not keep them waiting: show the top of the panel within a tenth of a second and all of it within about a third, and finish soon after. Speshell shows the panel itself once the entrance goes, so the entrance's last frame must show the panel exactly as it is, or the panel jumps: ease every distortion, tint, and overlay to nothing, let that frame draw, and emit `finished()` on the next tick. `just check` compares the two. Before removing the entrance, Speshell sets `panel` to null, so a `ShaderEffectSource` bound to it lets the panel show in the same frame; bind `sourceItem` to `panel` rather than keeping your own reference.

**Dashboard backdrop.** Painted over the theme's base color and clipped to the panel's cut-corner shape; the cards and text sit on it. The launcher paints it too, at the launcher's size (about 540 × 400 px against the dashboard's 420 × 1050), so it must hold up in a short, wide box. It receives `theme`, like the dashboard transition. Speshell renders it once into a texture and redraws it only when its properties change, so it must not animate. Keep it within a few percent of `theme.bg` wherever text may land: it sits behind every panel, including the calendar and the notes.

**Dashboard interactions.** Small effects where the user's hand is on the dashboard: dragging a slider, flipping a switch, picking something. Created while the dashboard shows, over the whole panel and above its content, and given no input. It receives `theme`, and Speshell calls its functions, with points and rects in its own coordinates:

| Function | Called when |
|---|---|
| `slide(point at, real dx)` | A slider's knob, centered at `at`, moved `dx` px under the user's drag or wheel. Called for each step of the move. |
| `release(point at)` | The user let go of a slider's knob. |
| `pick(rect area, point at)` | The user picked something: an audio device (its radio dot), a segment, a menu choice, a sidebar panel, a workspace, a bar button. `at` is where the pointer clicked, which may lie outside `area` (a device row clicked on its name picks its radio dot), or the middle of `area` for a keyboard pick or a menu choice; start the effect there, since a wide control's middle can be far from the pointer. |
| `toggle(rect area, bool on)` | The user turned a switch on or off; its thumb ends at the right end of `area` when on and the left when off. |

Keep each effect brief (under a second) and small around the control; the panel stays usable under it. Draw nothing and run nothing while idle: `lib/Particles.qml` is a pool of short-lived particles whose clock runs only while one lives. Its clock follows the dashboard's speed, and with the dashboard's transitions off Speshell does not create interactions.

**Knob.** The thumb of the dashboard's sliders and switches, filling the thumb's square; it may draw outside it. It receives `theme`, `pressed`, `hovered`, `checked` (a switch's state; always `true` on a slider), and `travel`, the thumb's position along its track in px, which moves only under the user's hand: roll or spin it by that. Like the backdrop, it stays with transitions off, so animate it only while held or hovered.

Speshell destroys a transition inside its finishing signal, so nothing may run after the emit. Take time from `EffectClock`, never from your own timers or `Date`. It ticks at the frame rate of the user's power mode (`[Power] mode`, exposed as `frameRate`: every frame the display shows at `maximum`, 60 Hz at `balanced`) and follows their speed for that surface (`[Appearance] launcherTransitionSpeed`, `dashboardTransitionSpeed`, or `wallpaperTransitionSpeed`, exposed as `timeScale`), so its `clock`, `simTime`, and `dt` already run fast or slow. Never assume a frame lasts 1/60 s: a simulation that steps once per frame should step by the time since its last step, as `fire/Flames.qml` does. With transitions off, or in power saver, Speshell does not create them; power saver also drops the interactions and the knob, keeping only the still backdrop.

## Style

Effects draw in flat, anti-aliased color bands for a cel-shaded look, and shape the captured panel or outgoing wallpaper with a second shader. Ambient animation while the launcher is open stays outside the panel or is masked from it. Air sets the bar for polish: layered depth, small secondary particles, and organic randomness rather than regular, repeated shapes.

## How each works

- **Cosmos** draws its solar system analytically in one shader: tilted orbits, cel-shaded planets, a ringed giant, a moon that passes behind its planet. A lens-edged portal reveals the panel and the old wallpaper.
- **Fire** runs a quarter-resolution fluid simulation through a recursive `ShaderEffectSource`, stepping once per rendered frame by the time since its last step.
- **Air** draws streaks along the stream function of an ideal 2D flow (breeze around an ellipse, vortex, source or sink) bent by curl noise, so they never cross. Leaves and dust ride analytic orbits.
- **Water** draws tubes along a spiral and along the panel's rounded border, modulated by waves from each head, with drag-and-gravity droplets. The sheet and ripple refract the captured images; the sheet's caustics are warped Voronoi edges. Orbs, currents, and mist travel along the border pushed outward, so they never cross the panel.
- **Earth** builds stone, cracks, and shards from Voronoi cells, and boulders from faceted polygons whose faces are shaded by their turning normals as they tumble.
- **Relâmpago** draws the racing panel from its capture with a motion-blurred ghost, dithered along its speed and tinted red, and a bolt-edged ribbon: a centerline that slants along each run and jumps back by less than the ribbon's width, so the edges step. The bolts on the sliders and the backdrop are polylines of uneven runs, drawn by their distance to the nearest few segments so the corners stay whole. Speed lines are dashes in hashed rows at three depths; arcs along the border follow `rrArc` with piecewise-linear noise for their kinks. Sparks, smoke, and lightning strikes, bursts, and arcs are particles; a strike draws from its item's top, so turning the item aims it. The wallpaper tears along the bolt's path, each half sampled with taps kept inside it, so the torn edge stays sharp and glows.

On the dashboard, Cosmos reuses its portal, opening from a flare on the Speshell mark; Fire reuses its burn front and flame simulation, spreading down from the mark; Air blows the panel in behind a ragged front of wind streaks, its rows lagging by noise; Water slides a sheet of water down it from the top edge, a foam crest ahead and a waterline behind, the panel bent and lit by caustics between them; Earth raises it as Voronoi blocks, top rows first, each found by testing the nearby blocks shifted back by their own offsets; and Relâmpago strikes a bolt down it and shows each row outward from the bolt once it has passed. The backdrops are a nebula lane, banked flames, cloud banks with curling wind, an underwater view, rock strata with jade, and asphalt with a checkered flag and a forked bolt.

On the dashboard's controls, each effect spawns particles from `lib/Particles.qml`, each a small `ShaderEffect` that draws one kind of bit by its age: star dust, glints, and constellations that draw themselves star by star; flames standing on a burning streak, sparks, embers, flashes of ignition, and smoke; streaks of wind that blow a dragged knob along, wisps, leaves, and curls of wind; drops that drip off, leap in, or fly off to land in ripples, and crown splashes with the jet that follows; rock chips, dust, and jade shards; sparks, arcs, discharges, lightning strikes, and tire smoke. Each knob is one small shader turned by its travel, clockwise as it moves right, as a ball rolls: a planet whose moon orbits, an ember, a ball of wind, a drop that stretches by how far a spring-damped copy of its travel lags behind, a faceted stone that rolls, and a racing wheel that reaches back to the track's start to draw a bolt along the fill.

## Cost

GPU time per frame at 1080p on an RTX 3070 (`just perf`):

| Effects | Launcher open | Launcher entrance and exit | Wallpaper | Dashboard entrance | Dashboard controls |
|---|---|---|---|---|---|
| Cosmos | 0.09 ms | 0.09 ms | 0.01 ms | 0.04 ms | 0.13 ms |
| Fire | 0.33 ms | 0.29 ms | 0.20 ms | 0.22 ms | 0.21 ms |
| Air | 0.19 ms | 0.26 ms | 0.26 ms | 0.21 ms | 0.08 ms |
| Water | 0.41 ms | 0.31 ms | under 0.07 ms | 0.12 ms | 0.11 ms |
| Earth | 0.39 ms | 0.48 ms | 0.23 ms | 0.41 ms | 0.10 ms |
| Relâmpago | 0.08 ms | 0.08 ms | 0.19 ms | 0.03 ms | 0.08 ms |

The controls column is the whole controls scene, its backdrop included, while effects play. Nothing runs while the launcher is hidden, the wallpaper is still, the dashboard has finished its entrance, and no control effect is playing. The backdrop renders once when the dashboard or launcher first shows or the theme changes. Re-measure after a change and update this table.
