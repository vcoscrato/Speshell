import QtQuick
import "../theme" as ThemeModule
import "." as Components

Components.IconButton {

    property bool active: false
    size: ThemeModule.Theme.controlHeightSmall
    iconName: active ? "loader" : "refresh"
    iconSize: ThemeModule.Theme.iconSizeSmall
    iconColor: active ? ThemeModule.Theme.warning : ThemeModule.Theme.subtext
    iconSpinning: active
}
