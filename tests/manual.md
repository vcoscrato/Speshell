# Speshell manual test checklist

Run automated checks first with `make lint` and `make test`, then exercise the
relevant scenarios from this list on a real Hyprland session.

## Dashboard and launcher

- Open and close the special workspace repeatedly; confirm focus returns to the
  previous window and hidden widgets stop active work.
- Open, close, and toggle the launcher through IPC on each connected monitor.
- Exercise application, calculator, panel bang, configured bang, and web-search
  results using both pointer and keyboard input.

## Displays

- Prepare a harmless layout or mode change, apply it, and select **Keep Changes**.
- Apply another change and allow the 15-second countdown to restore the previous
  layout while the dashboard remains open.
- Repeat the timeout test after closing the dashboard.
- Apply and select **Revert** immediately.
- Disconnect or reconnect a monitor during confirmation and verify Speshell
  attempts a best-effort rollback for displays that remain connected.
- Force a failed rollback when practical; verify the previous snapshot remains
  available through **Retry Revert**.
- Verify brightness reads and writes the configured or auto-detected backlight.

## Persistent data

- Create, edit, switch, delete, undo, and permanently delete notes.
- Relaunch while a note has a pending debounced save and verify no text is lost.
- Edit and reload `config.ini`; verify valid changes apply and invalid input opens
  the diagnostic window without overwriting the file.
- Launch several applications and confirm launcher usage ordering survives a
  relaunch.

## Integrations

- Exercise audio output/input volume, mute, device selection, and quick switch.
- Change output volume and mute with the keyboard; verify the OSD appears on the
  focused monitor, coalesces repeated presses, and never takes focus. Repeat with
  Speshell's slider and sidebar wheel and verify the OSD stays hidden.
- Toggle Wi-Fi, scan, connect to open and secured networks, and test a failure.
- Enable, scan, connect, and disconnect Bluetooth devices.
- Copy, select, and clear clipboard history; repeat without `cliphist` or
  `wl-clipboard` and confirm inline guidance remains usable.
- Send transient, persistent, actionable, resident, and critical notifications;
  verify DND, history, expiry, dismissal, and configured toast limits.
- Expand notifications containing long bodies and uninterrupted strings; verify
  all text is readable, the list grows up to its limit, and overflow can scroll.
- Enable weather and run a focus timer through completion.
- Exercise lock and cancel each confirmed power action before testing it for real.

## Readiness and input

- Enable weather without `curl`, select a missing backlight, or configure a
  missing locker. Confirm one aggregated warning appears after launch and the
  same issues appear under Settings → Integrations.
- Verify absent laptop battery or unconfigured optional tools do not create a
  startup warning.
- Repeat the dashboard and launcher checks after moving the special workspace to
  another monitor and after changing fractional monitor scale.
