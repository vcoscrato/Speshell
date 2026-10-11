# Prefer Qt 6 tools; on Arch, /usr/bin/qmllint may belong to Qt 5.
qt6_bin := shell('for d in /usr/lib/qt6/bin /usr/lib64/qt6/bin; do [ -d "$d" ] && echo "$d" && break; done; true')
qmllint := env("QMLLINT", if qt6_bin != "" { qt6_bin / "qmllint" } else { "qmllint" })
qmltestrunner := env("QMLTESTRUNNER", if qt6_bin != "" { qt6_bin / "qmltestrunner" } else { "qmltestrunner" })

[private]
default:
    @just --list

# Lint every QML module.
lint:
    {{ qmllint }} -W 0 shell.qml core/*.qml components/*.qml services/*.qml theme/*.qml widgets/*.qml

# Run the QML unit tests.
test:
    QT_QPA_PLATFORM=offscreen {{ qmltestrunner }} -input tests

# Build and install a package from this checkout, uncommitted changes included.
local-package-install:
    #!/bin/sh
    set -e
    builddir=$(mktemp -d /tmp/speshell-local.XXXXXX)
    printf 'Building local package in %s\n' "$builddir"
    mkdir -p "$builddir/src/speshell"
    cp PKGBUILD "$builddir/"
    tar --exclude='./src' --exclude='./pkg' --exclude='./speshell' --exclude='./*.pkg.tar.*' \
        -cf - . | tar -C "$builddir/src/speshell" -xf -
    cd "$builddir" && makepkg -efsi
