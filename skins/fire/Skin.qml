import QtQuick

// Fire: warm charcoal surfaces, ember accents, a burn-in launcher, and wallpapers
// that burn away to the next.
QtObject {
    readonly property int apiVersion: 1

    // Merged over the configured color scheme; omitted keys keep their scheme value.
    readonly property var palette: ({
        base:     "#1d1416",
        mantle:   "#170f11",
        crust:    "#100a0b",
        surface0: "#2b1d1f",
        surface1: "#3d2925",
        surface2: "#53372f",
        overlay0: "#7a5a4e",
        text:     "#f1e2d6",
        subtext0: "#b89c8c",
        subtext1: "#d3bba9",
        red:      "#e5482e",
        peach:    "#f58a3a",
        yellow:   "#f5c04a"
    })
    readonly property string accent: "#f58a3a"

    readonly property Component launcherTransition: Component {
        FireTransition {}
    }

    readonly property Component wallpaperTransition: Component {
        FireWallpaper {}
    }
}
