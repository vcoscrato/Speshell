pragma ComponentBehavior: Bound
// qmllint disable uncreatable-type
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

// The wallpaper on one screen's background layer.
PanelWindow {
    id: root

    required property var modelData

    screen: root.modelData
    color: ThemeModule.Theme.crust
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "speshell-wallpaper"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // The default wallpaper, under any theme wallpaper: the Speshell mark on the
    // theme's darkest color.
    Components.SpeshellMark {
        anchors.centerIn: parent
        size: 29 * Math.max(2, Math.round(root.height * 0.16 / 29))
        leftColor: ThemeModule.Theme.surface2
        // Opaque, so the overlapping strokes do not show their seams.
        rightColor: Qt.tint(ThemeModule.Theme.crust, ThemeModule.Theme.alpha(ThemeModule.Theme.accent, 0.6))
    }

    WallpaperView {
        anchors.fill: parent
        path: Services.ThemeService.shownWallpaper
        transition: Services.EffectsService.wallpaperTransition
        timeScale: Services.EffectsService.wallpaperSpeed
        frameRate: Services.EffectsService.frameRate
        pixelRatio: root.devicePixelRatio
    }
}
