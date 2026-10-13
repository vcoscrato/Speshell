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
  wrong password. "Last refreshed" shows the scan's age.
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
