import QtQuick

// Water effects: a launcher that arrives as a whip of water and clears into
// place, and wallpapers that ripple into the next.
// A theme picks them with `effects = water` in its theme.ini.
QtObject {
    readonly property int apiVersion: 1

    readonly property Component launcherTransition: Component {
        WaterTransition {}
    }

    readonly property Component wallpaperTransition: Component {
        WaterWallpaper {}
    }
}
