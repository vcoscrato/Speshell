import QtQuick
import QtQuick.Templates as T
import "../theme" as ThemeModule
import "." as Components

// A row of PopupMenu: an optional icon and the label, then a check on selectable rows or
// an arrow when it opens a submenu. `selected` marks the current choice; a click never
// toggles it.
T.MenuItem {
    id: root

    property bool selectable: false
    property bool selected: false

    implicitWidth: Math.max(implicitBackgroundWidth, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight, implicitContentHeight + topPadding + bottomPadding)
    horizontalPadding: ThemeModule.Theme.spacingSmall
    verticalPadding: ThemeModule.Theme.spacingMicro
    spacing: ThemeModule.Theme.spacingSmall
    font.family: ThemeModule.Theme.fontFamily
    font.pixelSize: ThemeModule.Theme.fontSizeSmall
    icon.width: ThemeModule.Theme.iconSizeSmall
    icon.height: ThemeModule.Theme.iconSizeSmall
    opacity: root.enabled ? 1.0 : ThemeModule.Theme.disabledOpacity

    Accessible.checkable: root.selectable
    Accessible.checked: root.selected

    contentItem: Item {
        implicitWidth: labelRow.implicitWidth + (marker.visible ? root.spacing + marker.width : 0)
        implicitHeight: Math.max(ThemeModule.Theme.controlHeightSmall, labelRow.implicitHeight)

        Row {
            id: labelRow

            anchors.verticalCenter: parent.verticalCenter
            spacing: root.spacing

            Image {
                anchors.verticalCenter: parent.verticalCenter
                visible: String(root.icon.source) !== ""
                width: root.icon.width
                height: root.icon.height
                source: root.icon.source
                sourceSize: Qt.size(root.icon.width * 2, root.icon.height * 2)
                fillMode: Image.PreserveAspectFit
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.text
                textFormat: Text.PlainText
                font: root.font
                color: root.selected ? ThemeModule.Theme.accent : ThemeModule.Theme.text
            }
        }

        Components.AppIcon {
            id: marker

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.subMenu !== null || root.selectable
            name: root.subMenu !== null ? "chevron-right" : "check"
            size: ThemeModule.Theme.iconSizeTiny
            iconColor: root.subMenu !== null ? ThemeModule.Theme.subtext : ThemeModule.Theme.accent
            opacity: root.subMenu !== null || root.selected ? 1.0 : 0.0
        }
    }

    background: Rectangle {
        radius: ThemeModule.Theme.borderRadiusSmall
        color: root.highlighted && root.enabled ? ThemeModule.Theme.cardHover : "transparent"
    }
}
