import QtQuick
import "../services" as Services
import "../theme" as ThemeModule
import "." as Components

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
            ? ThemeModule.Theme.selectedFill
            : "transparent"

        Components.SpeshellMark {
            anchors.centerIn: parent
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
        id: markMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.pointerInside = true
        onExited: root.pointerInside = false
        onCanceled: root.pointerInside = false
        onClicked: {
            if (!root.active)
                Services.EffectsService.picked(root, markMouse);
            root.activated();
        }
    }

    Components.HoverLabel {
        visible: root.containingWindowVisible && root.pointerInside
        text: "Home"
    }
}
