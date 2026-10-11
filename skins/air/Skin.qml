import QtQuick

// Air: cool slate surfaces with sky-blue and saffron accents, a launcher that gusts
// in out of a vortex, and wallpapers blown away by the next.
QtObject {
    readonly property int apiVersion: 1

    // Merged over the configured color scheme; omitted keys keep their scheme value.
    readonly property var palette: ({
        base:     "#151a20",
        mantle:   "#11151a",
        crust:    "#0c0f13",
        surface0: "#1f2630",
        surface1: "#2b3440",
        surface2: "#3a4553",
        overlay0: "#5d6b7c",
        text:     "#e6edf3",
        subtext0: "#9aa8b6",
        subtext1: "#bcc7d2",
        peach:    "#e89a4a",
        yellow:   "#f0b44c"
    })
    readonly property string accent: "#7cc0ea"

    readonly property Component launcherTransition: Component {
        AirTransition {}
    }

    readonly property Component wallpaperTransition: Component {
        AirWallpaper {}
    }
}
