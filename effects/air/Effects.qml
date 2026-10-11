import QtQuick

// Air effects: a launcher that gusts in out of a vortex, and wallpapers blown
// away by the next.
// A theme picks them with `effects = air` in its theme.ini.
QtObject {
    readonly property int apiVersion: 1

    readonly property Component launcherTransition: Component {
        AirTransition {}
    }

    readonly property Component wallpaperTransition: Component {
        AirWallpaper {}
    }
}
