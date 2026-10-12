import QtQuick

// Cosmos effects: a launcher that opens out of a star with a small solar system
// circling it, and wallpapers that give way to a supernova shock front.
// A theme picks them with `effects = cosmos` in its theme.ini.
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
