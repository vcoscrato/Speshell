import QtQuick

// Water: deep-sea surfaces with a clear blue accent, a launcher that arrives as a
// whip of water and clears into place, and wallpapers that ripple into the next.
QtObject {
    readonly property int apiVersion: 1

    // Merged over the configured color scheme; omitted keys keep their scheme value.
    readonly property var palette: ({
        base:     "#0f1a22",
        mantle:   "#0c151c",
        crust:    "#081016",
        surface0: "#152530",
        surface1: "#1d3240",
        surface2: "#284354",
        overlay0: "#4a6577",
        text:     "#e3eef4",
        subtext0: "#93aab8",
        subtext1: "#b6c9d4"
    })
    readonly property string accent: "#4fb3d9"

    readonly property Component launcherTransition: Component {
        WaterTransition {}
    }

    readonly property Component wallpaperTransition: Component {
        WaterWallpaper {}
    }
}
