# Manual checks

What the unit tests can't reach: windows, devices, and Hyprland. Run the checks
for the areas a change touches on a real Hyprland session, after `just lint test`.

## Dashboard

- Open and close it a few times: focus returns to the previous window.
- With effects on, the panel doesn't blink or shift at the end of the entrance.
- Workspaces: tiles show app icons, and hovering one shows its last window's
  title. Clicking a tile shows that workspace under the dashboard, which stays open.
- Move the special workspace to another monitor and change fractional scale:
  everything still lines up.

## Bar

With `[Bar] position = top`, then `bottom`, each with `margin = 0` and `16`, on
every monitor:

- Tiled windows and the dashboard stay clear of the bar; fullscreen windows cover it.
- The bar is framed on every side that doesn't touch the screen's edge: docked at
  full width only toward the windows, at 50 % on three sides, floating at 50 % on all
  four. At full width it spans the whole screen. With `outline = full`, the frame
  runs along the screen's edges too, as thick as elsewhere.
- Workspaces show this monitor's; clicking one shows it. The mark opens and
  closes the dashboard.
- Each panel icon, the clock, the track's cover, and a running timer open the same
  panel the dashboard shows, toward the screen's middle, with the theme's knobs and
  control effects. A click outside,
  Escape, or the same icon closes it; opening the dashboard closes it too. Typing a
  Wi-Fi password works.
- Play/pause and the track's cover sit left of the clock and a running timer right
  of it; the clock doesn't move when either appears. Play/pause toggles without
  opening anything, the cover dims while paused, and hovering it names the track.
  Switching players, or pausing one while another plays, shows the playing one. At
  `width = 20` with music and a timer, the bar grows to fit and nothing overlaps.
  Whatever `[Audio] panelMode` says, the speaker icon opens only the speaker and
  the mic icon only the mic.
- Scrolling over the speaker, mic, or (with a backlight) brightness icon changes it.
  Tray menus and hover labels open toward the screen's middle.
- Turning it off in Settings removes it and the reserved space at once.

## Launcher

- `speshell launcher open|close|toggle` works on each monitor.
- Apps, the calculator, panel bangs, your own bangs and web search all work with
  mouse and keyboard. **Tab** completes a bang, and `vsc` finds Visual Studio Code.
- A `Terminal=true` app such as `btop` opens in a terminal.
- Launch counts still order the results after a relaunch.
- With a launcher transition, typing works during the entrance. Closing with
  **Escape** or by launching an app plays the exit, clicks pass through during
  it, and reopening mid-exit works.

## Themes

- Switch themes with `!theme`, the Themes panel and `speshell theme set ID`,
  including a theme without effects. Colors, wallpaper and transitions follow,
  and the old launcher exit finishes.
- After a relaunch, the chosen theme's colors are there from the first frame.
- Tooltips, dropdown menus (Settings, Displays), a tray app's right-click menu
  with its submenus, scrollbars, and selected text all draw in the theme's
  colors, and so do the effects of a theme that borrows another theme's effects.
- A wallpaper added under `~/.config/speshell/themes/<shipped theme>/` joins
  that theme.
- A bad color in `theme.ini` or a broken `Effects.qml` raises a notification, and
  the launcher still opens.
- With **Draw wallpaper** off, the background is left alone and `!wall` isn't
  offered. Toggling it in Settings › Themes adds and removes the background.

## Displays

- Apply a change and press **Keep Changes**: it stays.
- Apply a change and wait 15 s: it reverts, both with the dashboard open and closed.
- Apply a change and press **Revert**: it reverts at once.
- Unplug a monitor during the countdown: the displays still connected roll back.
- When a rollback fails, **Retry Revert** stays available.
- `!mirror` mirrors the displays, and running it again extends them.
- Brightness controls the configured or auto-detected backlight.

## Settings and config

- Changing a toggle, a choice or a dropdown applies at once and flashes **Saved**.
- At 150 % text size, wide controls move under their labels and tooltips stay
  inside the dashboard.
- Editing `config.ini` in an editor applies on save without Reload. An invalid
  edit keeps the old settings and shows the error in Settings. A later change in
  Settings keeps your edits in the file.
- An invalid `config.ini` at launch opens the error window and leaves the file
  untouched.
- **Edit** in About opens the config, with and without `$EDITOR` set.

## Notes

- Create, edit, switch, delete, undo and permanently delete notes.
- Editing the open note in another editor shows the new text, or a warning if
  there are unsaved edits.
- Relaunching right after typing loses nothing.

## Audio, network, Bluetooth, clipboard

- Volume, mute, device choice and quick switch work for output and input.
- Volume keys show the OSD on the focused monitor, merge repeated presses, and
  never take focus. Changes from Speshell's own slider or the sidebar wheel don't
  show it.
- Network and Bluetooth only scan after refresh and stop scanning when you leave
  the panel. Connect and disconnect devices, including a secured network and a
  wrong password.
- VPN and WireGuard profiles connect and disconnect from the Network panel. A
  login's questions show on the profile's row, and a failed saved password can be
  typed again.
- Clipboard history lists, selects and clears entries. Without `cliphist` or
  `wl-clipboard`, the panel explains what's missing.

## Notifications and activity

- Transient, persistent, actionable, resident and critical notifications follow
  DND, expiry, dismissal and the toast limit. DND survives a relaunch, and
  critical notifications still show while it's on.
- `notify-send -p`, then `notify-send -r <id>`, updates the toast and history
  in place.
- Toasts open on the focused monitor. Long bodies and unbroken strings wrap, and
  the expanded list scrolls.
- `speshell activity set test active Test` shows the activity OSD, and
  `speshell activity clear test` hides it. Running `wf-recorder` shows the
  recording activity, and **Stop** ends it.
- `speshell tool dictate` shows Listening… and, run again, Transcribing…
  without delay, then types the text into the focused window. **Discard** and
  `speshell tool dictate cancel` drop it without typing.

## Tools

- The Tools button (bar) and rail icon (dashboard) show only with a tool
  installed, and list only installed tools; one installed while Speshell runs
  appears the next time the panel opens.
- Each tool closes the bar's dropdown before it selects or captures, so it doesn't
  show in the result. The capture tools leave the dashboard open, and dictation
  closes it. The selection uses the theme's accent.
- Copy text, Scan code, Screenshot (area and screen) and Pick color copy their
  result and toast it; cancelling the selection does nothing. Screenshot's
  Annotate opens Swappy, and a link's Open opens the browser.
- Record shows in the panel with its time and in the bar's icon; a click, the
  OSD's **Stop**, or `speshell tool record` saves it and toasts Open.
- `speshell tool ocr` without tesseract toasts what to install.

## Home chips and power

- Weather shows a condition icon and temperature (a moon after sunset) under the
  date, without shifting Home.
- The focus timer shows its chip, preset row, and extra time and Stop while
  running. At the end, an accent toast appears even with DND on.
- Lock works. Other power actions arm on the first click (a double-click only
  arms them) and disarm when the countdown runs out.

## Missing tools

- Weather with no `curl`, a missing backlight or a missing locker each show in
  one warning after launch and in About. The weather issue also shows in
  Settings › Weather.
- A desktop without a battery or the optional tools shows no startup warning.
