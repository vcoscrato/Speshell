import QtQuick

// Air effects: a launcher that a whirlpool of wind draws in out of a vortex, and
// wallpapers blown away by the next.
// A theme picks them with `effects = air` in its theme.ini.
QtObject {
    readonly property int apiVersion: 1

    readonly property Component launcherTransition: Component {
        LauncherTransition {}
    }

    readonly property Component wallpaperTransition: Component {
        WallpaperTransition {}
    }

    readonly property Component dashboardTransition: Component {
        DashboardTransition {}
    }

    readonly property Component dashboardBackdrop: Component {
        DashboardBackdrop {}
    }

    readonly property Component dashboardInteractions: Component {
        Interactions {}
    }

    readonly property Component knob: Component {
        Knob {}
    }
}
