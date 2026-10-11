pragma ComponentBehavior: Bound
// qmllint disable uncreatable-type
import QtQuick
import Quickshell
import Quickshell.Wayland
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

    WallpaperView {
        anchors.fill: parent
        path: Services.WallpaperService.current
        transition: Services.SkinService.wallpaperTransition
        pixelRatio: root.devicePixelRatio
    }
}
