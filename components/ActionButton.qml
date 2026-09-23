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
    implicitHeight: Math.max(ThemeModule.Theme.controlHeight, contentRow.implicitHeight + ThemeModule.Theme.spacingMedium)
    height: implicitHeight
    implicitWidth: Math.max(ThemeModule.Theme.controlHeight, contentRow.implicitWidth + ThemeModule.Theme.spacingLarge)
    radius: ThemeModule.Theme.borderRadiusSmall
    opacity: enabled ? 1.0 : ThemeModule.Theme.disabledOpacity
    color: actionArea.containsMouse && root.enabled
        ? ThemeModule.Theme.alpha(root.toneColor, ThemeModule.Theme.tintStrong)
        : ThemeModule.Theme.controlFill
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
            size: ThemeModule.Theme.iconSizeSmall
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
