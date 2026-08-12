import QtQuick
import "../theme" as ThemeModule

Item {
    id: root

    signal activated()

    property bool active: false
    property bool pointerInside: false
    readonly property bool containingWindowVisible: !!(root.Window
        && root.Window.window
        && root.Window.window.visible)

    Connections {
        target: root.Window ? root.Window.window : null

        function onVisibleChanged() {
            if (!root.containingWindowVisible)
                root.pointerInside = false;
        }
    }

    width: parent ? parent.width : ThemeModule.Theme.sidebarIconSize
    height: ThemeModule.Theme.sidebarIconSize

    Accessible.role: Accessible.Button
    Accessible.name: "Home"
    Accessible.onPressAction: root.activated()

    Rectangle {
        anchors.centerIn: parent
        width: 38
        height: 38
        radius: ThemeModule.Theme.borderRadiusSmall
        color: root.pointerInside
            ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.10)
            : "transparent"

        Item {
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
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.pointerInside = true
        onExited: root.pointerInside = false
        onCanceled: root.pointerInside = false
        onClicked: root.activated()
    }

    Rectangle {
        anchors.left: parent.right
        anchors.leftMargin: ThemeModule.Theme.spacingTiny
        anchors.verticalCenter: parent.verticalCenter
        width: homeLabel.implicitWidth + ThemeModule.Theme.spacingLarge
        height: 26
        radius: ThemeModule.Theme.borderRadiusSmall
        visible: root.containingWindowVisible && root.pointerInside
        color: ThemeModule.Theme.surface2
        border.width: ThemeModule.Theme.borderWidth
        border.color: Qt.rgba(
            ThemeModule.Theme.accent.r,
            ThemeModule.Theme.accent.g,
            ThemeModule.Theme.accent.b,
            0.42
        )
        z: 100

        Text {
            id: homeLabel

            anchors.centerIn: parent
            text: "Home"
            textFormat: Text.PlainText
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.text
        }
    }
}
