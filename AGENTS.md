Validation before handing changes back ONLY WHEN NEEDED:

```bash
qmllint shell.qml core/*.qml components/*.qml services/*.qml theme/*.qml widgets/*.qml
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
- `theme/` contains palettes and geometry/typography tokens.
- `assets/icons/tabler/` contains the pinned Tabler SVG subset and its upstream license.

Prefer deleting unused QML modules over keeping broad helper surfaces. This repo should stay small and direct.

## Packaging Notes

The Arch `PKGBUILD` uses the Git repository source, so plain `makepkg -si` is for normal package installs. Use `make local-package-install` when pacman must install a package built from the dirty checkout.

The package owns `/usr/share/speshell` and `/usr/bin/speshell`. User config and data live under:

- `~/.config/speshell/config.jsonc`
- `~/.local/share/speshell`

Package upgrades and removal should not overwrite those user files.
