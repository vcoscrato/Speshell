# Speshell

> Your screen is yours! Claim it back with Speshell.

A [QuickShell](https://quickshell.outfoxxed.me/) dashboard for Hyprland with no bar and no dock. It lives on a special workspace and appears on demand, even over fullscreen apps.

A personal setup first, largely built with AI. Borrow whatever is useful.

<p align="center">
  <img src=".github/print.png" width="100%" alt="Speshell panel on a Wayland desktop" />
</p>

## Features

- Home: each workspace's apps (click to show it under the dashboard), media, notifications
- Clock, weather, focus timer, calendar
- Markdown notes and clipboard history
- Media (MPRIS), audio output and input
- Displays (extend or mirror) and brightness
- Network, Bluetooth, battery, power, tray
- Notifications with history and Do Not Disturb
- Launcher: apps, calculator, panels, web bangs
- Tools: dictation, copy text from the screen (OCR), screenshots, screen recording, QR codes, color picker
- Activity indicator for screen recording, dictation, and anything that publishes over IPC
- Themes with wallpapers and animated effects
- Experimental bar (`[Bar] position = top` or `bottom`): workspaces, clock, playing track, timer, tray, and icons that open the dashboard's own panels

Widgets for missing hardware or tools hide themselves.

## Requirements

QuickShell ≥ 0.3, Hyprland, PipeWire/WirePlumber, NetworkManager, BlueZ, libnotify.

Optional: `brightnessctl`, `curl` (weather), `hyprlock`, `matugen` (app themes), `cliphist`, `wl-clipboard`, `xdg-utils`, and the tools' programs below.

## Tools

The **Tools** panel, in the bar and the dashboard, runs each tool whose programs are installed; the others don't show. Areas are picked with a selection in the theme's colors, and results arrive as toasts.

| Tool | Does | Needs |
|---|---|---|
| Dictation | Records until run again, then types and copies what you said | `pipewire`, `whisper.cpp`, `wtype`, `wl-clipboard`, `curl` (model download) |
| Copy text | Copies the text in an area | `grim`, `slurp`, `tesseract` and a `tesseract-data-*` per language, `wl-clipboard` |
| Screenshot | Saves an area or the screen to Pictures/Screenshots and copies it; Annotate opens it in Swappy | `grim`, `slurp`, `wl-clipboard`, optionally `swappy` |
| Record | Records an area or the screen, with sound, to Videos/Recordings until run again | `wf-recorder`, `slurp` |
| Scan code | Copies a QR code or barcode, offering to open links | `grim`, `slurp`, `zbar`, `wl-clipboard` |
| Pick color | Copies a pixel's hex color | `hyprpicker`, `wl-clipboard` |

`[Tools]` in the config sets the OCR and dictation languages, dictation vocabulary, and Whisper model. Bind them in Hyprland with `speshell tool`:

```lua
hl.bind("SUPER + D", hl.dsp.exec_cmd("speshell tool dictate"))
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("speshell tool dictate cancel"))
hl.bind("Print", hl.dsp.exec_cmd("speshell tool screenshot"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("speshell tool ocr"))
hl.bind("SUPER + R", hl.dsp.exec_cmd("speshell tool record"))
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("speshell tool record screen"))
```

## Install

On Arch:

```bash
git clone https://github.com/vcoscrato/speshell.git
cd speshell
makepkg -si
```

The first run seeds `~/.config/speshell/config.ini`; upgrades never touch it or `~/.local/share/speshell`.

## Hyprland

```lua
-- Set [Appearance] panelWorkspace = special:dash to match.
local ws = "dash"

hl.bind("SUPER + GRAVE", hl.dsp.workspace.toggle_special(ws))
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("speshell launcher"))

hl.workspace_rule({
    workspace = "special:" .. ws,
    persistent = true,
    gaps_in = 8,
})

hl.on("hyprland.start", function()
    hl.exec_cmd("speshell --no-duplicate --daemonize")
end)
```

Speshell sets the workspace's `gaps_out` so its windows tile beside the panel, and updates them when `panelWidth` or `panelMargin` changes.

## Configuration

Common options are in the dashboard's **Settings** panel. Everything else is in `~/.config/speshell/config.ini`, documented by [`config.example.ini`](config.example.ini). Edits apply on save; an invalid file keeps the previous settings and shows the error.

## Launcher

`speshell launcher [open|close|toggle]`

| Input | Result |
|---|---|
| text | Apps and panels by name, initials, or fuzzy match; web search if nothing matches |
| `2 * (8 + 4)`, `= sqrt(144)` | Calculator; Enter copies the result |
| `!network`, `!yt query` | Open a panel, or use a bang from `[Launcher.Bangs]` |
| `? query` | Search with `[Launcher] searchUrl` |
| `!theme`, `!wall` | Pick a theme or wallpaper |

Unknown bangs go to the search engine, so its own bangs work too.

## Themes

Speshell ships Cosmos (the default), four elements (Fire, Air, Water, and Earth), and Relâmpago, a racing theme. Each has a palette, a wallpaper, launcher and wallpaper effects, and a dashboard that enters in its own style over a still painted backdrop, with themed slider and switch knobs and small effects as you use them (see [extras/](extras/README.md)). Pick one in the **Themes** panel or with `!theme`.

Set `drawWallpaper = true` under `[Appearance]` to let Speshell draw the desktop background. It is off by default so another wallpaper tool can stay in charge. `launcherTransitionSpeed`, `dashboardTransitionSpeed`, and `wallpaperTransitionSpeed` (0–3, default 1) speed up or slow down each surface's transitions, and 0 turns them off; the dashboard's also paces the effects on its sliders, switches, and choices. `[Power] mode` sets their frame rate: `maximum` animates at the display's refresh rate, `balanced` (the default) at 60 fps, and `saver` turns the effects off along with the interface's own motion. `shuffleAtLaunch` picks at random each time Speshell starts: `wallpaper` (another wallpaper of the theme), `theme` (another theme), or `both`; the default is `off`. Settings › Themes sets all of these.

Each theme remembers the wallpaper last set for it, so switching back to a theme brings that wallpaper back; a theme you have not picked a wallpaper for starts with its first.

A theme is a folder with an optional `theme.ini` and any images. Add your own under `~/.config/speshell/themes`; a folder named after a shipped theme adds wallpapers to it, and its `theme.ini` replaces the shipped one.

```ini
# ~/.config/speshell/themes/sunset/theme.ini
[Theme]
name = Sunset
effects = fire

[Colors]
base = #1d1315
text = #f3e3d3
accent = #f0702f
```

Colors use the keys of [`extras/themes/cosmos/theme.ini`](extras/themes/cosmos/theme.ini); missing ones come from Cosmos. Custom effects go in `~/.local/share/speshell/effects` (see [extras/effects](extras/effects/README.md)).

### App themes

Other apps can follow the theme. Speshell writes the active palette to `~/.local/share/speshell/palette.json` in [matugen](https://github.com/InioX/matugen)'s JSON format and, when it changes, sets GTK's `color-scheme` to the theme's light or dark and runs `matugen json` on it if `~/.config/matugen/config.toml` exists. matugen renders the templates listed there and runs their hooks, so which apps follow, and how they reload, is up to that config. If matugen fails, a notification shows its error.

Templates see each color under Speshell's names (`{{colors.accent.default.hex}}`, `colors.base`, `colors.surface0`, …), under the Material names matugen templates use (`colors.primary`, `colors.surface_container`, `colors.on_surface`, …), and as base16 (`{{base16.base0d.default.hex}}`), so templates written for matugen work as they are. Each hue also comes as tints over `base` for apps without transparency: `colors.green_15`, `green_30`, and `green_50` are green at that percent. `{{mode}}` is `dark` or `light`, from the theme's `base` color.

The file is rewritten only when the palette changes, so restarting Speshell leaves the apps alone. After editing the matugen config, run `matugen json ~/.local/share/speshell/palette.json` to render it.

## CLI

```bash
speshell theme list | get | set ID | shuffle [ID] | rescan
speshell wallpaper get | set PATH
speshell tool list | dictate [cancel] | ocr | screenshot [region|screen] | record [region|screen] | qr | color
speshell activity set ID STATE LABEL [DETAIL] [ICON] [TONE]
speshell activity list | clear ID | refresh
```

## Development

```bash
just lint test
just shaders   # compile effect shaders; needed once in a checkout
```

`bin/speshell` run from a checkout uses that checkout. Hardware behavior is checked by hand with [`tests/manual.md`](tests/manual.md); agent notes are in [AGENTS.md](AGENTS.md).

Icons are a subset of [Tabler Icons](https://github.com/tabler/tabler-icons) (MIT), in `assets/icons/tabler/`.
