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
    opacity: enabled ? 1.0 : ThemeModule.Theme.disabledOpacity

    color: root.checked
        ? root.activeColor
        : ThemeModule.Theme.alpha(ThemeModule.Theme.surface2, 0.4)
    border.width: ThemeModule.Theme.borderWidth
    border.color: root.checked
        ? root.activeColor
        : ThemeModule.Theme.controlBorder

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

    // Compact Thumb Handle
    Rectangle {
        width: switchMouse.pressed ? 16 : 14
        height: 14
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? (root.width - width - 3) : 3

        color: root.checked ? ThemeModule.Theme.bg : ThemeModule.Theme.subtext

        Behavior on x {
            NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing }
        }

        Behavior on width {
            NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing }
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

    Controls.ToolTip.visible: root.tooltipText !== "" && switchMouse.containsMouse
    Controls.ToolTip.text: root.tooltipText
    Controls.ToolTip.delay: root.tooltipDelay
}
