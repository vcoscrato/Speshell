import QtQuick
import QtQuick.Controls
import "../theme" as ThemeModule

Rectangle {
    id: root

    property bool checked: false
    property color activeColor: ThemeModule.Theme.accent
    property string tooltipText: ""
    property int tooltipDelay: 300

    signal toggled(bool newState)

    width: 42
    height: 28
    radius: height / 2
    activeFocusOnTab: root.enabled
    opacity: enabled ? 1.0 : 0.45
    color: "transparent"
    border.width: root.activeFocus ? 2 : 0
    border.color: root.activeColor

    Accessible.role: Accessible.CheckBox
    Accessible.name: root.tooltipText
    Accessible.checked: root.checked
    Accessible.onPressAction: {
        if (root.enabled)
            root.toggled(!root.checked);
    }

    Keys.onPressed: function(event) {
        if (!root.enabled || event.isAutoRepeat)
            return;
        if (event.key === Qt.Key_Return
                || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.toggled(!root.checked);
            event.accepted = true;
        }
    }

    Rectangle {
        id: track
        width: 38
        height: 20
        radius: height / 2
        anchors.centerIn: parent
        color: root.checked
            ? Qt.rgba(root.activeColor.r, root.activeColor.g, root.activeColor.b, 0.28)
            : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.18)
        border.width: ThemeModule.Theme.borderWidth
        border.color: root.checked
            ? Qt.rgba(root.activeColor.r, root.activeColor.g, root.activeColor.b, 0.9)
            : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.35)

        Behavior on color {
            ColorAnimation { duration: ThemeModule.Theme.animDuration }
        }

        Behavior on border.color {
            ColorAnimation { duration: ThemeModule.Theme.animDuration }
        }

        Rectangle {
            width: 14
            height: 14
            radius: height / 2
            x: root.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            color: root.checked ? root.activeColor : ThemeModule.Theme.subtext

            Behavior on x {
                NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutCubic }
            }

            Behavior on color {
                ColorAnimation { duration: ThemeModule.Theme.animDuration }
            }
        }
    }

    MouseArea {
        id: switchMouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.toggled(!root.checked)
    }

    ToolTip.visible: root.tooltipText !== "" && (switchMouse.containsMouse || root.activeFocus)
    ToolTip.text: root.tooltipText
    ToolTip.delay: root.tooltipDelay
}
