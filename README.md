# Speshell Elements

Elemental [Speshell](https://github.com/vcoscrato/Speshell) skins. Each element brings its own launcher entrance and exit, a wallpaper transition, and a matching palette. There is one skin per element: fire, air, water, and earth.

The effects are original work inspired by the four elements. This repository ships no third-party artwork. Bring your own wallpapers.

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

Requires Speshell with skin API v1 and Qt 6 shader tools (`qt6-shadertools` on Arch).

```bash
make link    # compile shaders and symlink skins into ~/.local/share/speshell/skins
```

Speshell picks the skin from the wallpaper. Point it at a wallpaper folder and give each skin a subfolder:

```ini
# ~/.config/speshell/config.ini
[Appearance]
wallpapers = ~/Pictures/Wallpapers
```

```
~/Pictures/Wallpapers/
├── fire/          any wallpaper in here, including nested folders, uses the fire skin
│   └── zuko/
├── air/
└── misc.jpg       no skin
```

Then pick a wallpaper with `!wall` in the launcher, or `speshell wallpaper set PATH`.

Qt caches compiled QML, so edits to a skin's `.qml` files take effect after restarting Speshell. Shader edits need `make` and a restart too. Use the lab to iterate without restarting.

## How it works

Each element draws its motion in shaders, in flat, anti-aliased color bands for a cel-shaded look, and shapes the captured launcher panel or outgoing wallpaper with another shader.

- **Fire** runs a low-resolution fluid simulation at a quarter of screen resolution and a fixed 60 Hz step. It feeds back into itself through a recursive `ShaderEffectSource`, and buoyancy plus curl-noise turbulence carry fuel and heat. The panel burns in and out along ragged fronts.
- **Air** needs no simulation. Its strokes are drawn analytically along log spirals, so they stay crisp at any size, and the panel is twisted by a vortex warp.
- **Water** draws its whip as a shaded tube along a spiral, its streams as tubes along the launcher's rounded border, and the sheet and ripple as refraction of the captured panel or wallpapers.
- **Earth** builds its stone, cracks, and shards from Voronoi cells, its boulders as faceted convex polygons, and draws dust and rock chips analytically.

GPU time per frame at 1080p on an RTX 3070 (`make perf`). The open launcher is measured once the entrance has finished; the transitions are averaged over their whole run.

| Skin | Launcher open | Launcher entrance and exit | Wallpaper |
|---|---|---|---|
| Fire | 0.33 ms | 0.29 ms | 0.20 ms |
| Air | 0.27 ms | 0.44 ms | 0.25 ms |
| Water | 0.13 ms | 0.17 ms | under 0.07 ms |
| Earth | 0.10 ms | 0.18 ms | 0.23 ms |

Each effect covers only the area around the launcher it needs. Nothing runs while the launcher is hidden and the wallpaper is still.

## Development

The lab renders skins offscreen through an invisible 1×1 overlay surface, so nothing appears on screen. It needs a running Wayland session.

```bash
make preview SKIN=fire SCENE=launcher    # or SCENE=wallpaper
make check                               # every skin and scene; fails on warnings
make perf SKIN=fire SCENE=launcher       # GPU time per frame at 1080p
```

`make preview` writes `lab/out/<skin>-<scene>.mp4`, a five-frame contact strip `<skin>-<scene>-strip.png`, the raw frames, and the log. It takes a few seconds.

- **Frame-exact time.** Lab scenes drive the shared `EffectClock` with virtual time, 1/60 s per rendered frame, so captures match real playback however slowly frames are saved. Effects must take their time from `EffectClock`, never from their own timers or `Date`.
- **Wallpapers.** The lab generates two plain stand-in wallpapers. Set `WALL_A=... WALL_B=...` to preview against your own.
- **Real host.** The wallpaper scene runs Speshell's own `core/WallpaperView.qml` from `SPESHELL_DIR`, which defaults to `../speshell` and then `/usr/share/speshell`. The launcher scene mimics `LauncherOverlay` with a mock panel, and likewise destroys the transition inside its finishing signal.
- **Timing.** `CLOSE_AT` sets when the launcher scene closes, and `SWITCH_AT` sets when the wallpaper scene switches.
- **Cost.** `make perf` renders 1 and then many offscreen copies of a scene every frame and reports the slope, which is the GPU time of one instance. It doubles the copies, up to 96, until the frame time clearly rises above the display's refresh interval; below that, the result is an upper bound. To measure only the open launcher, keep it open and start late: `CLOSE_AT=30 PERF_FROM=1.5 DURATION=4.5 make perf SKIN=air`.

Layout:

- `lib/` holds `common.glsl` (noise, curl, signed distances, banding, burn fronts, spiral strokes, Voronoi cells, arc length around a rounded rect) and `EffectClock.qml`.
- `skins/<element>/Skin.qml` is the entry point Speshell loads. Each skin reaches `lib/` through its `common` symlink, which keeps working when the skin itself is symlinked into Speshell.
- `skins/<element>/shaders/*.frag` are the GLSL sources. `make` compiles them to `.qsb`.
- `lab/` holds the harness, the scenes, and the preview, check, and perf scripts.

Adding an element: create `skins/<name>/` with a `common -> ../../lib` symlink and a `Skin.qml` that declares `apiVersion: 1`. Then iterate with `make preview SKIN=<name>` and finish with `make check`.
