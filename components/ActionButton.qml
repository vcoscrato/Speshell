import QtQuick
import "../theme" as ThemeModule
import "." as Components

Rectangle {
    id: root

    property string label: ""
    property string iconName: ""
    property color toneColor: ThemeModule.Theme.accent

    signal activated()

    width: implicitWidth
    height: 34
    implicitWidth: Math.max(34, contentRow.implicitWidth + ThemeModule.Theme.spacingLarge)
    radius: ThemeModule.Theme.borderRadiusSmall
    opacity: enabled ? 1.0 : 0.55
    color: actionArea.containsMouse && root.enabled
        ? Qt.rgba(root.toneColor.r, root.toneColor.g, root.toneColor.b, 0.16)
        : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.15)
    border.width: ThemeModule.Theme.borderWidth
    border.color: actionArea.containsMouse && root.enabled
        ? root.toneColor
        : "transparent"

    Accessible.role: Accessible.Button
    Accessible.name: root.label
    Accessible.onPressAction: {
        if (root.enabled)
            root.activated();
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: ThemeModule.Theme.spacingTiny

        Components.AppIcon {
            name: root.iconName
            size: 14
            iconColor: actionArea.containsMouse && root.enabled ? root.toneColor : ThemeModule.Theme.text
            anchors.verticalCenter: parent.verticalCenter
            visible: root.iconName !== ""
        }

        Text {
            text: root.label
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: actionArea.containsMouse && root.enabled ? root.toneColor : ThemeModule.Theme.text
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: actionArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.activated()
    }
}
