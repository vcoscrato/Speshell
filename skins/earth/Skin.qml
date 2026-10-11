import QtQuick

// Earth: warm stone surfaces with an Earth Kingdom green accent, a launcher that
// rises out of the ground as a slab, and wallpapers that crack and crumble away.
QtObject {
    readonly property int apiVersion: 1

    // Merged over the configured color scheme; omitted keys keep their scheme value.
    readonly property var palette: ({
        base:     "#1a1712",
        mantle:   "#15120e",
        crust:    "#0f0d0a",
        surface0: "#26221b",
        surface1: "#352f25",
        surface2: "#463e31",
        overlay0: "#6b604d",
        text:     "#ece4d4",
        subtext0: "#a89c86",
        subtext1: "#c8bda8",
        green:    "#8fbf5a",
        yellow:   "#d9b44a"
    })
    readonly property string accent: "#8fbf5a"

    readonly property Component launcherTransition: Component {
        EarthTransition {}
    }

    readonly property Component wallpaperTransition: Component {
        EarthWallpaper {}
    }
}
