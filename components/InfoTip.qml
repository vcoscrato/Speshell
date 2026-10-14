import QtQuick
import "../theme" as ThemeModule
import "." as Components

// Info icon that explains the item beside it while hovered.
Item {
    id: root

    property string text: ""

    implicitWidth: ThemeModule.Theme.iconSizeTiny + ThemeModule.Theme.spacingTiny * 2
    implicitHeight: implicitWidth

    Accessible.role: Accessible.StaticText
    Accessible.name: root.text

    HoverHandler {
        id: hover
        cursorShape: Qt.WhatsThisCursor
    }

    Components.AppIcon {
        anchors.centerIn: parent
        name: "info"
        size: ThemeModule.Theme.iconSizeTiny
        iconColor: hover.hovered ? ThemeModule.Theme.text : ThemeModule.Theme.overlay
    }

    Components.Tooltip {
        visible: hover.hovered && root.text !== ""
        delay: 150
        text: root.text
    }
}
