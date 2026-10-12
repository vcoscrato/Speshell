Validation before handing changes back ONLY WHEN NEEDED:

```bash
just lint test
git diff --check
timeout 5s quickshell --no-color -p .
```

`quickshell --reload` is not available in QuickShell v0.3. Use Speshell's Settings panel Reload button or restart the process.

## Architecture

- `shell.qml` starts strict config loading, applies validated global settings, and gates either `Runtime` or `ConfigErrorWindow`.
- `core/` contains the runtime composition, dashboard surfaces, widget registry/loading, special-workspace tracking, launcher, config-error, and toast windows.
- `widgets/` contains user-facing cards and panels.
- `services/` contains singleton system integrations, config/launcher providers, and shared media, notification, and dashboard state.
- `components/` contains reusable QML UI primitives.
- `theme/` contains the default palette and geometry/typography tokens.
- `assets/icons/tabler/` contains the pinned Tabler SVG subset and its upstream license.
- `extras/` contains the shipped `themes/`, `effects/`, and shared `lib/`, plus the unshipped `paintings/` (shaders that render the theme wallpapers) and `lab/` (offscreen harness). `extras/README.md` maps who edits what; `extras/effects/README.md` is the effects API. Shaders compile with `just shaders`.

Prefer deleting unused QML modules over keeping broad helper surfaces. This repo should stay small and direct.

- Style through `Theme` tokens: spacing, control heights, icon sizes, radii, and interaction states (`controlFill`, `selectedFill`, `tint*`, `disabledOpacity`, `Theme.alpha()`). Add a token only when several components share the value.
- When UI changes system state, call a small domain service (for example `AudioService.stepOutputVolume()` or `BrightnessService.setPercent()`) instead of running processes or writing backend objects from widgets.

## Packaging Notes

The Arch `PKGBUILD` uses the Git repository source, so plain `makepkg -si` is for normal package installs. Use `just local-package-install` when pacman must install a package built from the dirty checkout. It does not restart Speshell; a running one keeps the shaders it already loaded until restarted.

The package owns `/usr/share/speshell` and `/usr/bin/speshell`, which is installed from `bin/speshell`. User config and data live under:

- `~/.config/speshell/config.ini`
- `~/.local/share/speshell`

Package upgrades and removal should not overwrite those user files.
