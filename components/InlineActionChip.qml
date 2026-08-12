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

    radius: 11
    height: 22
    width: chipContent.width + 16
    opacity: enabled ? 1.0 : 0.45
    color: chipMouse.containsMouse
        ? Qt.rgba(toneColor().r, toneColor().g, toneColor().b, armed ? 0.32 : 0.24)
        : Qt.rgba(toneColor().r, toneColor().g, toneColor().b, armed ? 0.24 : 0.12)
    border.width: ThemeModule.Theme.borderWidth
    border.color: Qt.rgba(toneColor().r, toneColor().g, toneColor().b, armed ? 0.85 : 0.45)

    Accessible.role: Accessible.Button
    Accessible.name: root.text
    Accessible.onPressAction: {
        if (root.enabled)
            root.activated();
    }

    Row {
        id: chipContent
        anchors.centerIn: parent
        spacing: 4

        Components.AppIcon {
            name: root.iconName
            size: 11
            iconColor: root.toneColor()
            visible: root.iconName !== ""
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.text
            font.pixelSize: 10
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
