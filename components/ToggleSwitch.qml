import QtQuick
import QtQuick.Controls as Controls
import "../theme" as ThemeModule

Rectangle {
    id: root

    property bool checked: false
    property color activeColor: ThemeModule.Theme.accent
    property string tooltipText: ""
    property int tooltipDelay: 300

    signal toggled(bool newState)

    width: 36
    height: 20
    radius: height / 2
    activeFocusOnTab: root.enabled
    opacity: enabled ? 1.0 : 0.45

    color: root.checked
        ? root.activeColor
        : Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.4)
    border.width: root.activeFocus ? 2 : 1
    border.color: root.activeFocus
        ? ThemeModule.Theme.accent
        : (root.checked ? root.activeColor : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.3))

    Behavior on color {
        ColorAnimation { duration: ThemeModule.Theme.animDuration }
    }

    Behavior on border.color {
        ColorAnimation { duration: ThemeModule.Theme.animDuration }
    }

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

    // Compact Thumb Handle
    Rectangle {
        id: thumb
        width: switchMouse.pressed ? 16 : 14
        height: 14
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? (root.width - width - 3) : 3

        color: root.checked ? ThemeModule.Theme.bg : ThemeModule.Theme.subtext

        Behavior on x {
            NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutCubic }
        }

        Behavior on width {
            NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutCubic }
        }

        Behavior on color {
            ColorAnimation { duration: ThemeModule.Theme.animDuration }
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

    Controls.ToolTip.visible: root.tooltipText !== "" && (switchMouse.containsMouse || root.activeFocus)
    Controls.ToolTip.text: root.tooltipText
    Controls.ToolTip.delay: root.tooltipDelay
}
