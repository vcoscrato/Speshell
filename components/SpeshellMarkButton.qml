import QtQuick
import QtQuick.Controls
import "../theme" as ThemeModule

Item {
    id: root

    signal activated()

    property bool active: false

    width: parent ? parent.width : ThemeModule.Theme.sidebarIconSize
    height: ThemeModule.Theme.sidebarIconSize
    activeFocusOnTab: true

    Accessible.role: Accessible.Button
    Accessible.name: "Home"
    Accessible.onPressAction: root.activated()

    Keys.onPressed: function(event) {
        if (event.isAutoRepeat)
            return;
        if (event.key === Qt.Key_Return
                || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.activated();
            event.accepted = true;
        }
    }

    Rectangle {
        id: tile

        anchors.centerIn: parent
        width: 38
        height: 38
        radius: ThemeModule.Theme.borderRadiusSmall
        color: pointer.containsMouse
            ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.10)
            : "transparent"
        border.width: root.activeFocus ? 2 : 0
        border.color: ThemeModule.Theme.accent

        Item {
            id: mark

            anchors.centerIn: parent
            width: 29
            height: 29

            Rectangle {
                x: 0
                y: 2
                width: 2
                height: 25
                color: ThemeModule.Theme.text
            }
            Rectangle {
                x: 0
                y: 2
                width: 9
                height: 2
                color: ThemeModule.Theme.text
            }
            Rectangle {
                x: 0
                y: 25
                width: 9
                height: 2
                color: ThemeModule.Theme.text
            }

            Rectangle {
                x: 27
                y: 2
                width: 2
                height: 25
                color: ThemeModule.Theme.accent
            }
            Rectangle {
                x: 20
                y: 2
                width: 9
                height: 2
                color: ThemeModule.Theme.accent
            }
            Rectangle {
                x: 20
                y: 25
                width: 9
                height: 2
                color: ThemeModule.Theme.accent
            }

            Repeater {
                model: [0, 60, -60]

                delegate: Rectangle {
                    required property real modelData

                    anchors.centerIn: parent
                    width: 2
                    height: 15
                    radius: 1
                    rotation: modelData
                    color: ThemeModule.Theme.accent
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: -6
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 18
            color: ThemeModule.Theme.accent
            visible: root.active
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }

    ToolTip.visible: pointer.containsMouse || root.activeFocus
    ToolTip.text: "Home"
    ToolTip.delay: 150
}
