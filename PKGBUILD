# Maintainer: Victor Coscrato <vcoscrato@users.noreply.github.com>

pkgname=speshell-git
pkgver=0
pkgrel=1
pkgdesc="Hyprland dashboard and launcher built with Quickshell"
arch=('any')
url="https://github.com/vcoscrato/Speshell"
license=('MIT')
depends=(
  'bash'
  'bluez'
  'coreutils'
  'hyprland'
  'libnotify'
  'networkmanager'
  'pipewire'
  'quickshell>=0.3.0'
  'systemd'
  'which'
  'wireplumber'
)
makedepends=('git')
optdepends=(
  'curl: weather lookup'
  'brightnessctl: brightness controls'
  'cliphist: clipboard history'
  'hyprlock: default screen locker for power actions'
  'wl-clipboard: clipboard capture and copy actions'
  'xdg-utils: opening the config when VISUAL and EDITOR are unset'
)
provides=('speshell')
conflicts=('speshell')
source=("speshell::git+${url}.git")
sha256sums=('SKIP')

pkgver() {
  if [ -d speshell ]; then
    cd speshell
  fi
  printf 'r%s.g%s' \
    "$(git rev-list --count HEAD)" \
    "$(git rev-parse --short=7 HEAD)"
}

package() {
  cd speshell

  install -d "$pkgdir/usr/share/speshell"
  install -m644 shell.qml config.example.jsonc "$pkgdir/usr/share/speshell/"
  cp -r assets components core services theme widgets "$pkgdir/usr/share/speshell/"

  install -Dm644 README.md "$pkgdir/usr/share/doc/speshell/README.md"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 assets/icons/tabler/LICENSE \
    "$pkgdir/usr/share/licenses/$pkgname/LICENSE.tabler-icons"

  install -Dm755 /dev/stdin "$pkgdir/usr/bin/speshell" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

readonly app_dir="${SPESHELL_QML_DIR:-/usr/share/speshell}"
readonly config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly data_root="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly config_dir="$config_root/speshell"
readonly data_dir="$data_root/speshell"
readonly config_file="$config_dir/config.jsonc"

if [[ ! -r "$app_dir/shell.qml" ]]; then
  printf 'speshell: shell.qml not found in %s\n' "$app_dir" >&2
  exit 1
fi

install -d -m755 "$config_root" "$data_root"
install -d -m755 "$config_dir" "$data_dir"

if [[ ! -e "$config_file" && ! -L "$config_file" ]]; then
  install -m644 "$app_dir/config.example.jsonc" "$config_file"
fi

if [[ "${1:-}" == "launcher" ]]; then
  shift
  action="${1:-open}"
  case "$action" in
    open|close|toggle) ;;
    *)
      printf 'speshell: unknown launcher action: %s\n' "$action" >&2
      printf 'usage: speshell launcher [open|close|toggle]\n' >&2
      exit 2
      ;;
  esac

  if /usr/bin/quickshell ipc --any-display -p "$app_dir" call launcher "$action" >/dev/null 2>&1; then
    exit 0
  fi

  /usr/bin/quickshell -p "$app_dir" --no-duplicate --daemonize

  for _ in $(seq 1 30); do
    if /usr/bin/quickshell ipc --any-display -p "$app_dir" call launcher "$action" >/dev/null 2>&1; then
      exit 0
    fi
    sleep 0.05
  done

  printf 'speshell: failed to contact launcher IPC target\n' >&2
  exit 1
fi

exec /usr/bin/quickshell -p "$app_dir" "$@"
EOF

  # Qt portals identify the process through its desktop ID. Keep the metadata
  # entry hidden from launchers: Speshell is opened through Hyprland bindings.
  install -Dm644 /dev/stdin \
    "$pkgdir/usr/share/applications/speshell.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Speshell
Comment=Hyprland dashboard and launcher
Exec=speshell --no-duplicate
TryExec=speshell
Terminal=false
NoDisplay=true
Categories=Utility;
EOF
}
