import QtQuick
import QtQuick.Controls as Controls
import "../theme" as ThemeModule

Controls.Slider {
    id: root

    property color trackColor: Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.5)
    property color progressColor: ThemeModule.Theme.accent
    property color handleColor: ThemeModule.Theme.bg
    property color handleBorderColor: ThemeModule.Theme.accent
    property real trackHeight: 8
    property real handleSize: 18
    signal wheelAdjusted(real nextValue)

    from: 0
    to: 100
    stepSize: 1
    height: 32

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onWheel: function(wheel) {
            if (wheel.angleDelta.y === 0)
                return;
            var step = root.stepSize > 0 ? root.stepSize : 5;
            var delta = wheel.angleDelta.y > 0 ? step : -step;
            var newVal = Math.max(root.from, Math.min(root.to, root.value + delta));
            if (newVal !== root.value)
                root.wheelAdjusted(newVal);
            wheel.accepted = true;
        }
    }

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: root.trackHeight
        radius: height / 2
        color: root.trackColor
        clip: true

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: root.progressColor

            Behavior on width {
                NumberAnimation { duration: 60; easing.type: Easing.OutCubic }
            }

            Behavior on color {
                ColorAnimation { duration: ThemeModule.Theme.animDuration }
            }
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: sliderMouse.containsMouse || root.pressed ? 20 : root.handleSize
        height: sliderMouse.containsMouse || root.pressed ? 20 : root.handleSize
        radius: height / 2
        color: root.handleColor
        border.width: 2
        border.color: root.handleBorderColor

        Behavior on width {
            NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutCubic }
        }

        Behavior on height {
            NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutCubic }
        }

        MouseArea {
            id: sliderMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }
}
