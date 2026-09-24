# Speshell

> Your screen is yours! Claim it back with Speshell.

I started Speshell with the idea that the user should own 100% of their screen real estate. No dock, no bar, nothing visible all the time. Speshell is always within reach, ready to spawn into the foreground.

Speshell is especially useful for heavy fullscreen applications. If you need quick settings, such as audio output control, volume adjustment, app launching, or simply the time, Speshell can appear over your fullscreen app as a Hyprland layer-shell surface without disturbing your workflow.

> Speshell is built with [QuickShell](https://quickshell.outfoxxed.me/). Major parts of this repository were built with AI. So don't expect pristine code quality. This is a personal setup first, but the code and config are here if you want to borrow pieces for your own system.

<p align="center">
  <img src=".github/print.png" width="100%" alt="Speshell panel on a Wayland desktop" />
</p>

## Features

- Clock, date, weather, and focus timer
- Multi-note Markdown scratchpad and clipboard history widgets
- Media controls through MPRIS
- Output and input audio controls
- Hyprland display overview, layout presets, and brightness controls
- Integrated app, calculator, panel, bang, and web launcher
- Network and Bluetooth controls
- Notification daemon with history and DND
- Activity controls for screen recording, dictation, and other long-running tools
- Calendar, battery status, power actions, and system tray

Unsupported widgets hide automatically. For example, a desktop without a battery does not show the battery widget.

## Requirements

- **QuickShell** >= v0.3.0
- **Hyprland** for layer-shell surfaces, focus grabbing, and display controls
- **PipeWire/WirePlumber** for audio
- **NetworkManager**, **BlueZ**, and **libnotify** for network, Bluetooth, and timer notifications

Optional integrations:

- **brightnessctl** for brightness
- **curl** for opt-in weather lookup
- **hyprlock** for the default screen-lock and lock-before-sleep actions
- **hyprsunset** for Night Light
- **cliphist** for clipboard history
- **wf-recorder** for screen recording activity detection and control
- **whisper.cpp** for dictation transcription activity detection
- **wl-clipboard** for clipboard capture and every copy action, including calculator results and error reports
- **xdg-utils** to open the config when `$VISUAL` and `$EDITOR` are unset or no terminal is found

Speshell starts its own `wl-paste --watch cliphist store` process while running; a separate clipboard-history watcher is not required.

## Install

On Arch Linux:

```bash
git clone https://github.com/vcoscrato/Speshell.git ~/Documents/speshell
cd ~/Documents/speshell
makepkg -si
```

Then run:

```bash
speshell --no-duplicate --daemonize
```

The package installs immutable app files under `/usr/share/speshell` and seeds your user config on first launch:

- `~/.config/speshell/config.ini`
- `~/.local/share/speshell`

Package upgrades do not replace your config or runtime data.

Notes remain ordinary text files under `~/.local/share/speshell/notes/`; the
selected note is recorded in the adjacent `.active` file. Writes replace files
atomically, and an existing `~/.local/share/speshell/scratchpad.txt` is moved to
`notes/Scratchpad.txt` on first launch after upgrading. Edits made to the open
note by other programs appear in Speshell; if Speshell also has unsaved text, it
keeps that text and warns before the next save replaces the outside change.

Notes render as Markdown until clicked. While editing, **Enter** finishes and
**Shift+Enter** inserts a new line; clicking elsewhere also finishes. Deleting
a note offers a five-second Undo window.

## Hyprland Setup

Set the Speshell workspace and panel geometry:

```ini
[Appearance]
panelWorkspace = special:dash
panelWidth = 420
panelMargin = 16
```

Configure the matching special workspace, keybinds, and startup hook in Hyprland Lua:

```lua
-- Must match [Appearance] panelWorkspace without the "special:" prefix.
local speshell_workspace = "dash"

hl.bind("SUPER + GRAVE", hl.dsp.workspace.toggle_special(speshell_workspace))
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("speshell launcher"))

-- 16px panel margin + 420px panel width + 12px spacing = 448px left gap
hl.workspace_rule({
    workspace = "special:" .. speshell_workspace,
    persistent = true,
    gaps_in = 8,
    gaps_out = { top = 16, right = 16, bottom = 16, left = 448 },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/bin/speshell --no-duplicate --daemonize")
end)
```

Hyprland gap values use CSS order: top, right, bottom, left. The panel itself is layer-shell, so it does not reserve compositor space; the workspace gap gives the special workspace room for the panel.

## Configuration

Edit `~/.config/speshell/config.ini`. The bundled `config.example.ini` is the canonical self-documenting reference and the file used to bootstrap a new config.

The INI format intentionally replaces the earlier `config.jsonc` format without an automatic migration. If you have an old config, copy the settings you still want into `config.ini`; the old file is left untouched and ignored.

Gruvbox is the default color scheme. Catppuccin, Nord, Dracula, Tokyo Night, Rosé Pine, Solarized Dark, and Everforest remain available. The Settings panel uses compact category pages for common appearance, audio, launcher, integration, and notification options; advanced mappings and commands remain in `config.ini`.

Speshell validates malformed lines and the settings that can put the runtime into a bad state: enums, booleans, numeric ranges, URL templates, and launcher bangs. Other entries are ignored. Validation failures open a line-aware diagnostic window; saving a corrected file reloads it automatically, or select **Retry**. Comments use `#` or `;` on their own line. Important numeric constraints are:

| INI property | Valid values |
|---|---|
| `[Appearance] textScale` | `0.8`–`1.5` |
| `[Appearance] panelWidth` | `240`–`1200` |
| `[Appearance] panelMargin` | `0`–`128` |
| `[Audio] scrollStep` | `1`–`100` |
| `[Launcher] width` | `280`–`1200` |
| `[Launcher] visibleRows` | `1`–`20` |
| `[Notifications] maxVisible` | `-1` or `1`–`50` |

Speshell watches `config.ini` and applies valid edits immediately. If an edit is invalid, the previous settings stay active and **Settings** shows the first error. **Settings → Advanced → Open** edits the file in `$VISUAL` or `$EDITOR` inside your terminal (`$TERMINAL`, `xdg-terminal-exec`, or a common emulator), or with the desktop's default application when no editor is set.

`[Notifications] maxVisible` limits how many notification toasts are on screen at once; older toasts are dismissed first. Toasts open on the focused monitor. Do Not Disturb persists across restarts and still shows critical notifications.

Output-volume changes made outside the dashboard, including the standard `wpctl` media-key bindings, show a compact on-screen volume indicator. Changes made with Speshell's own slider or sidebar wheel stay quiet.

### Activities

Long-running foreground utilities appear in a compact activity control at the top of the focused display. When `wf-recorder` or `dictate-toggle` is installed, Speshell checks the process list every two seconds (every second while an activity is running); otherwise it does not poll. It detects `wf-recorder` automatically and provides a **Stop** action. It also follows the existing `dictate-toggle` workflow through its `pw-record` and `whisper-cli` processes, showing distinct listening and transcribing states with a **Finish** action while listening. Existing Hyprland bindings that launch `record-toggle` or `dictate-toggle` do not need to change.

Other tools can publish the same generic activity model over IPC:

```bash
speshell activity set sync active "Syncing files" "Uploading changes" refresh info
speshell activity list
speshell activity clear sync
```

Valid active states are `active`, `busy`, `paused`, and `error`; `idle`, `inactive`, `stopped`, or `complete` clear the published activity. Icons use Speshell's semantic icon names and tones may be `neutral`, `success`, `warning`, `error`, or `info`. Process adapters remain separate from the shared model, so future utilities can integrate without adding service-specific properties to the activity UI.

### Layout

The dashboard owns its layout. This keeps the surface stable as features evolve and leaves configuration focused on behavior:

```text
┌───────┬────────────────────┐
│       │ Clock              │ fixed header
│ upper │────────────────────│
│ rail  │ active panel       │ Home: media + notifications
│       │                    │
│ tray  │────────────────────│
│       │ Calendar / utility │ fixed bottom area
│ lower │                    │
└───────┴────────────────────┘
```

The upper rail starts with Audio, followed by Displays, Battery, Notes, Clipboard, Network, and Bluetooth. Audio combines speaker and microphone controls by default; set `[Audio] panelMode = separate` to restore separate output and microphone icons. Unsupported entries hide automatically, so Battery does not appear on a desktop without one. System tray items stay centered in the free rail area.

The Speshell mark opens Home, which contains Now Playing and Notifications. Calendar, Settings, About, and Power always occupy the lower rail and share the exclusive bottom area. Calendar is selected by default; selecting another utility replaces it, and selecting the active utility again returns to Calendar.

The former JSONC layout properties have no INI equivalents. The old `configPanel` navigation alias still opens Settings.

Available panel destinations:

| Name | Widget |
|------|--------|
| `main` | Home panel with media and notifications |
| `clock` | Clock, weather, and focus timer |
| `notes` | Persistent multi-note Markdown scratchpad |
| `clipboardManager` | Clipboard history |
| `nowPlaying` | Full media player in the main widget |
| `audioControl` | Output volume |
| `audioInputControl` | Input volume |
| `displayControl` | Hyprland displays |
| `networkPanel` | Network |
| `bluetoothPanel` | Bluetooth |
| `notificationCenter` | Notifications in the main widget |
| `calendar` | Calendar |
| `batteryStatus` | Battery |
| `settings` | Theme and configuration actions |
| `about` | Speshell, QuickShell, and system information |
| `powerMenu` | Power actions |

### Launcher

Open it with `speshell launcher`; `speshell launcher close` and `speshell launcher toggle` are also available.

| Input | Result |
|---|---|
| Plain text | Search installed applications and Speshell panels by name, keyword, initials (`vsc`), or letters in order; offer a web search when nothing matches |
| `= expression` | Force calculator mode |
| Unambiguous expression | Calculate without the `=` prefix |
| `!name` | Open an available Speshell panel or use a web bang |
| `? query` | Search with `[Launcher] searchUrl` |

```text
2 * (8 + 4)       calculate and copy the result
= sqrt(144)       explicit calculator mode
!network          open Speshell on the Network panel
!yt QML tutorial  use a configured web bang
? QML singleton  search with the configured search engine
```

Panel bangs are navigation only. The launcher lists every built-in destination supported by the machine. `!home`, `!clock`, `!media`, and `!notifications` open the app-owned Home layout; utility bangs select their panel in the fixed bottom area.

| Bang | Widget | Bang | Widget |
|---|---|---|---|
| `!about` | `about` | `!audio` | `audioControl` |
| `!battery` | `batteryStatus` | `!bluetooth` | `bluetoothPanel` |
| `!calendar` | `calendar` | `!clipboard` | `clipboardManager` |
| `!clock` | `clock` | `!display` | `displayControl` |
| `!home` | `main` | `!media` | `nowPlaying` |
| `!mic` | `audioInputControl` | `!network` | `networkPanel` |
| `!notes` | `notes` | `!notifications` | `notificationCenter` |
| `!power` | `powerMenu` | `!settings` (or `!config`) | `settings` |

The calculator supports `+`, `-`, `*`, `/`, `%`, `^`, parentheses, unary signs, `pi`, `e`, and these functions: `sqrt`, `abs`, `round`, `floor`, `ceil`, `sin`, `cos`, `tan`, `log`, `ln`, `min`, and `max`. Activating a result copies it.

Keyboard controls are **Up/Down** to select, **Enter** to activate, **Tab** to complete the selected bang, and **Escape** to close. Selecting a configured bang without search terms completes it instead of opening an empty search. Applications marked `Terminal=true` open in your terminal emulator.

Configure web search and custom bangs with HTTPS URL templates containing exactly one `{query}` placeholder. Bang names use lowercase letters, digits, and hyphens; built-in panel aliases are reserved.

```ini
[Launcher]
width = 540
visibleRows = 5
searchUrl = https://duckduckgo.com/?q={query}

[Launcher.Bangs]
gh = https://github.com/search?q={query}
yt = https://www.youtube.com/results?search_query={query}
```

Unknown bangs are passed intact to `[Launcher] searchUrl`, which enables provider-native bangs when the selected search engine supports them.

### Integrations and power

Audio quick-switch settings match case-insensitive substrings against PipeWire/Pulse device names and descriptions. Add numbered entries in display order; empty sections show every device. Dedicated map sections rename matching PipeWire names or descriptions:

```ini
[Audio.QuickSwitch]
1 = Built-in Audio
2 = Display, HDMI

[Audio.InputQuickSwitch]
1 = Microphone

[Audio.DeviceNames]
alsa_output.pci-0000_00_1f.3.analog-stereo = Speakers

[Audio.InputDeviceNames]
alsa_input.pci-0000_00_1f.3.analog-stereo = Desk Microphone
```

Discover the available identifiers with:

```bash
pactl list sinks | grep -E "Name:|Description:"
pactl list sources | grep -E "Name:|Description:"
```

On systems with multiple entries in `/sys/class/backlight`, set `[Backlight] device` to the device that Speshell should read and pass to `brightnessctl`.

Display layout changes require confirmation. After applying a change, select **Keep Changes** within fifteen seconds or Speshell restores the previous modes, positions, scales, mirror relationships, and enabled outputs. Closing the dashboard does not cancel the rollback timer.

Weather lookup is disabled by default. Set `[Weather] enabled` to `true`; `location` controls the label and query. Leaving the location empty allows wttr.in to infer an approximate location from the request.

The power menu uses `hyprlock` by default. Lock runs immediately; Sleep, Log out, Restart, and Power off require confirmation. Sleep starts the locker, verifies that it remains active, and only then asks systemd to suspend. To use another blocking Wayland locker, set its executable and add optional numbered arguments:

```ini
[Power]
lockCommand = gtklock

[Power.Arguments]
1 = --daemonize
```

The locker process must remain running for the duration of the locked session. Lock and Sleep are disabled when the configured executable cannot be found. Action failures are shown inline in the power panel.

After startup, Speshell emits one aggregated warning when an explicitly configured integration cannot operate: enabled weather without `curl`, a missing configured backlight or `brightnessctl`, or an unavailable configured locker. The same diagnostics appear under **Settings → Integrations**. Unconfigured optional tools and absent laptop hardware remain silent.

## Development

Run deterministic tests and QML linting locally:

```bash
make test
make lint
```

`bin/speshell` is the same command the package installs as `/usr/bin/speshell`. Run from a checkout, it uses that checkout's QML files, so `bin/speshell launcher` or `bin/speshell activity list` exercise local changes; set `SPESHELL_QML_DIR` to point it elsewhere.

Hardware and compositor behavior is intentionally verified on a real Hyprland session. See [`tests/manual.md`](tests/manual.md) for the focused manual checklist.

## Third-party assets

Speshell uses a curated subset of [Tabler Icons](https://github.com/tabler/tabler-icons), distributed under the MIT license. The pinned version, copyright notice, and upstream license are included in `assets/icons/tabler/`.

Development and agent-facing notes live in [AGENTS.md](AGENTS.md).
