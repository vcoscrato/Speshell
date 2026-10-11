import QtQuick

// Earth effects: a launcher that rises out of the ground as a slab, and
// wallpapers that crack and crumble away.
// A theme picks them with `effects = earth` in its theme.ini.
QtObject {
    readonly property int apiVersion: 1

    readonly property Component launcherTransition: Component {
        LauncherTransition {}
    }

    readonly property Component wallpaperTransition: Component {
        WallpaperTransition {}
    }
}
