import QtQuick
import "../theme" as ThemeModule
import "." as Components

Rectangle {
    id: root

    property string text: ""
    property string iconName: ""
    property string tone: "neutral" // neutral | success | warning | error | info
    property bool armed: false

    signal activated()
    function toneColor() {
        return ThemeModule.Theme.toneColor(root.tone);
    }

    radius: height / 2
    implicitHeight: Math.max(22, chipContent.implicitHeight + ThemeModule.Theme.spacingSmall)
    height: implicitHeight
    width: chipContent.width + 16
    opacity: enabled ? 1.0 : ThemeModule.Theme.disabledOpacity
    color: ThemeModule.Theme.alpha(root.toneColor(),
        (chipMouse.containsMouse ? ThemeModule.Theme.tintStrong : ThemeModule.Theme.tintSubtle)
            + (root.armed ? ThemeModule.Theme.tintSubtle : 0))
    border.width: ThemeModule.Theme.borderWidth
    border.color: ThemeModule.Theme.alpha(root.toneColor(), root.armed ? ThemeModule.Theme.tintOutlineStrong : ThemeModule.Theme.tintOutline)

    Accessible.role: Accessible.Button
    Accessible.name: root.text
    Accessible.onPressAction: {
        if (root.enabled)
            root.activated();
    }

    Row {
        id: chipContent
        anchors.centerIn: parent
        spacing: ThemeModule.Theme.spacingTiny

        Components.AppIcon {
            name: root.iconName
            size: ThemeModule.Theme.iconSizeTiny
            iconColor: root.toneColor()
            visible: root.iconName !== ""
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.text
            font.pixelSize: ThemeModule.Theme.fontSizeCaption
            font.family: ThemeModule.Theme.fontFamily
            font.bold: true
            color: root.toneColor()
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            root.activated();
        }
    }
}
