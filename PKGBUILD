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
  'procps-ng'
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
  'wf-recorder: screen recording activity integration'
  'whisper-cpp: dictation transcription activity integration'
  'wl-clipboard: clipboard capture and copy actions'
  'xdg-utils: opening the config when VISUAL and EDITOR are unset or no terminal is found'
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
  install -m644 shell.qml config.example.ini "$pkgdir/usr/share/speshell/"
  cp -r assets components core services theme widgets "$pkgdir/usr/share/speshell/"

  install -Dm644 README.md "$pkgdir/usr/share/doc/speshell/README.md"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 assets/icons/tabler/LICENSE \
    "$pkgdir/usr/share/licenses/$pkgname/LICENSE.tabler-icons"

  install -Dm755 bin/speshell "$pkgdir/usr/bin/speshell"

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
