import QtQuick
import QtQuick.Controls
import "../theme" as ThemeModule
import "." as Components

Rectangle {
    id: root

    property string iconName: ""
    property int iconSize: ThemeModule.Theme.fontSizeLarge
    property color iconColor: ThemeModule.Theme.text
    property color hoverColor: ThemeModule.Theme.cardHover
    property real size: 36
    property real iconXOffset: 0
    property real iconYOffset: 0
    property bool iconSpinning: false
    property string tooltipText: ""
    property int tooltipDelay: 300
    property alias containsMouse: mouseArea.containsMouse

    signal clicked()

    onIconSpinningChanged: if (!root.iconSpinning) iconContainer.rotation = 0

    width: size
    height: size
    radius: size / 2
    activeFocusOnTab: root.enabled
    opacity: enabled ? 1.0 : 0.45
    color: mouseArea.containsMouse && root.enabled
        ? (mouseArea.pressed ? ThemeModule.Theme.surface2 : root.hoverColor)
        : "transparent"
    border.width: root.activeFocus ? 2 : 0
    border.color: ThemeModule.Theme.accent

    Accessible.role: Accessible.Button
    Accessible.name: root.tooltipText !== ""
        ? root.tooltipText
        : root.iconName
    Accessible.onPressAction: {
        if (root.enabled)
            root.clicked();
    }

    Keys.onPressed: function(event) {
        if (!root.enabled || event.isAutoRepeat)
            return;
        if (event.key === Qt.Key_Return
                || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Space) {
            root.clicked();
            event.accepted = true;
        }
    }

    Item {
        id: iconContainer
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.iconXOffset
        anchors.verticalCenterOffset: root.iconYOffset
        width: root.size
        height: root.size
        scale: mouseArea.pressed ? 0.85 : 1.0

        Components.AppIcon {
            anchors.centerIn: parent
            name: root.iconName
            size: root.iconSize
            iconColor: root.iconColor
            visible: root.iconName !== ""
        }

        Behavior on scale {
            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }

        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            running: root.iconSpinning
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: true
        onClicked: root.clicked()
    }

    ToolTip.visible: root.tooltipText !== "" && (mouseArea.containsMouse || root.activeFocus)
    ToolTip.text: root.tooltipText
    ToolTip.delay: root.tooltipDelay
}
