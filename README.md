# Speshell Elements

Elemental effects and themes for [Speshell](https://github.com/vcoscrato/Speshell). Each element brings its own launcher entrance, an animation while the launcher is open, an exit, and a wallpaper transition. Each nation's theme pairs its element's effects with a matching palette: Fire Nation, Air Nomads, Water Tribe, and Earth Kingdom.

The effects and wallpapers are original work inspired by the four elements; this repository ships no third-party artwork. Each theme comes with one plain, unbranded wallpaper, and you can add your own.

## Fire

- **Launcher entrance:** an ember flares at the lower left of the launcher. A burning edge sweeps across, and the launcher appears behind it with a white-hot line, an orange glow, and a char band.
- **While open:** flames keep simmering around the launcher's edges.
- **Launcher exit:** a hole burns through the middle of the panel. It scorches, chars, and spreads outward until the panel is gone.
- **Wallpaper:** the old wallpaper catches near the middle of the screen and burns away outward, revealing the new one.

## Air

- **Launcher entrance:** wind strokes spiral in from far out, each ending in a curl like the swirls of the Air Nomad emblem, and wrap the launcher. The launcher unwinds out of the vortex, wrung tight at the eye and settling outward.
- **While open:** wind strokes keep circling the launcher on staggered cycles, passing behind it, over a faint swirl of mist.
- **Launcher exit:** the launcher winds back into the vortex and vanishes as the gusts fly off outward.
- **Wallpaper:** a whirlwind eye opens in the middle of the screen and widens until the old wallpaper is gone, wringing it into the spin as gusts spiral out.

## Water

- **Launcher entrance:** a whip of water sweeps in from off screen, coils into an orb in the middle of the launcher, and spreads into a sheet in the launcher's shape that sloshes past its edges. The launcher shows through the rippling water, which then clears.
- **While open:** two streams of water chase each other around the launcher's border, swelling as they flow and shedding droplets from their tails.
- **Launcher exit:** the launcher turns back to water, draws into an orb, and whips away.
- **Wallpaper:** a drop lands in the middle of the screen and its ripple spreads out, refracting both wallpapers and carrying the new one in behind it.

## Earth

- **Launcher entrance:** the ground cracks open below the launcher, and the launcher punches up out of it as a faceted stone slab, flinging rock chips and dust. It lands with a jolt and the stone falls away.
- **While open:** boulders rise out of the ground one after another and hover around the launcher, bobbing and trickling grit.
- **Launcher exit:** the boulders drop, and the launcher turns back to stone and sinks into the ground in a cloud of dust.
- **Wallpaper:** cracks race across the old wallpaper from the middle of the screen, which then crumbles away shard by shard from the middle outward.

## Use

Requires Speshell with effects API v1, [just](https://github.com/casey/just), and Qt 6 shader tools (`qt6-shadertools` on Arch).

```bash
just link     # compile shaders and symlink the effects into ~/.local/share/speshell/effects
just themes   # copy the nation themes and wallpapers into ~/.config/speshell/themes (keeps existing files)
```

Each theme in `themes/` is a `theme.ini` with the nation's colors and its element's effects, plus a default wallpaper: Fire Nation (a volcano at ember dusk), Air Nomads (spires above a sea of clouds), Water Tribe (a polar night sea), and Earth Kingdom (mesas at golden hour). Add your own wallpapers next to them:

```
~/.config/speshell/themes/
├── fire-nation/
│   ├── theme.ini
│   ├── agni-kai.jpg
│   └── zuko/ember-island.png
└── air-nomads/
    └── theme.ini
```

Then pick a theme with `!theme` in the launcher. For Speshell to draw the wallpapers, set `drawWallpaper = true` under `[Appearance]` in its `config.ini`; then `!wall` picks a wallpaper too. Any other theme can use these effects with `effects = fire` (or `air`, `water`, `earth`) in its `theme.ini`.

Qt caches compiled QML, so edits to an effect's `.qml` files take effect after restarting Speshell. Shader edits need `just shaders` and a restart too. Use the lab to iterate without restarting. Edits to a `theme.ini` apply the next time the theme list is scanned, for example when opening `!theme`.

## How it works

Each element draws its motion in shaders, in flat, anti-aliased color bands for a cel-shaded look, and shapes the captured launcher panel or outgoing wallpaper with another shader.

- **Fire** runs a low-resolution fluid simulation at a quarter of screen resolution and a fixed 60 Hz step. It feeds back into itself through a recursive `ShaderEffectSource`, and buoyancy plus curl-noise turbulence carry fuel and heat. The panel burns in and out along ragged fronts.
- **Air** needs no simulation. Its strokes are drawn analytically along log spirals, so they stay crisp at any size, and the panel is twisted by a vortex warp.
- **Water** draws its whip as a shaded tube along a spiral, its streams as tubes along the launcher's rounded border, and the sheet and ripple as refraction of the captured panel or wallpapers.
- **Earth** builds its stone, cracks, and shards from Voronoi cells, its boulders as faceted convex polygons, and draws dust and rock chips analytically.

GPU time per frame at 1080p on an RTX 3070 (`just perf`). The open launcher is measured once the entrance has finished; the transitions are averaged over their whole run.

| Effects | Launcher open | Launcher entrance and exit | Wallpaper |
|---|---|---|---|
| Fire | 0.33 ms | 0.29 ms | 0.20 ms |
| Air | 0.27 ms | 0.44 ms | 0.25 ms |
| Water | 0.13 ms | 0.17 ms | under 0.07 ms |
| Earth | 0.10 ms | 0.18 ms | 0.23 ms |

Each effect covers only the area around the launcher it needs. Nothing runs while the launcher is hidden and the wallpaper is still.

## Development

The lab renders effects offscreen through an invisible 1×1 overlay surface, so nothing appears on screen. It needs a running Wayland session.

```bash
just preview fire launcher   # or: just preview water wallpaper
just check                   # every effect and scene; fails on warnings
just perf fire launcher      # GPU time per frame at 1080p
```

`just preview` writes `lab/out/<effect>-<scene>.mp4`, a five-frame contact strip `<effect>-<scene>-strip.png`, the raw frames, and the log. It takes a few seconds.

- **Frame-exact time.** Lab scenes drive the shared `EffectClock` with virtual time, 1/60 s per rendered frame, so captures match real playback however slowly frames are saved. Effects must take their time from `EffectClock`, never from their own timers or `Date`.
- **Wallpapers.** The lab generates two plain stand-in wallpapers. Set `WALL_A=... WALL_B=...` to preview against your own.
- **Real host.** The wallpaper scene runs Speshell's own `core/WallpaperView.qml` from `SPESHELL_DIR`, which defaults to `../speshell` and then `/usr/share/speshell`. The launcher scene mimics `LauncherOverlay` with a mock panel, and likewise destroys the transition inside its finishing signal.
- **Timing.** `CLOSE_AT` sets when the launcher scene closes, and `SWITCH_AT` sets when the wallpaper scene switches.
- **Cost.** `just perf` renders 1 and then many offscreen copies of a scene every frame and reports the slope, which is the GPU time of one instance. It doubles the copies, up to 96, until the frame time clearly rises above the display's refresh interval; below that, the result is an upper bound. To measure only the open launcher, keep it open and start late: `CLOSE_AT=30 PERF_FROM=1.5 DURATION=4.5 just perf air`.

Layout:

- `lib/` holds `common.glsl` (noise, curl, signed distances, banding, burn fronts, spiral strokes, Voronoi cells, arc length around a rounded rect) and `EffectClock.qml`.
- `effects/<element>/Effects.qml` is the entry point Speshell loads. Each effect reaches `lib/` through its `common` symlink, which keeps working when the effect itself is symlinked into Speshell.
- `effects/<element>/shaders/*.frag` are the GLSL sources. `just shaders` compiles them to `.qsb`.
- `themes/<nation>/` holds each nation's `theme.ini` and default wallpaper, which `just themes` installs.
- `backgrounds/*.frag` paint the default wallpapers. `just backgrounds` re-renders them at 3840×2160 into `themes/`.
- `lab/` holds the harness, the scenes, and the preview, check, and perf scripts.

Adding an element: create `effects/<name>/` with a `common -> ../../lib` symlink and an `Effects.qml` that declares `apiVersion: 1`. Then iterate with `just preview <name>` and finish with `just check`.
