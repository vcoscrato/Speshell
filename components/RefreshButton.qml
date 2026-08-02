import QtQuick
import "../theme" as ThemeModule
import "." as Components

Components.IconButton {
    id: root

    property bool active: false
    size: 30
    iconName: active ? "loader" : "refresh"
    iconSize: ThemeModule.Theme.fontSizeNormal
    iconColor: active ? ThemeModule.Theme.warning : ThemeModule.Theme.subtext
    iconSpinning: active
}
