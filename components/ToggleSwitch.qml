import QtQuick
import "../services" as Services
import "../theme" as ThemeModule
import "." as Components

Rectangle {
    id: root

    property bool checked: false
    property color activeColor: ThemeModule.Theme.accent
    property string tooltipText: ""
    property int tooltipDelay: 300

    signal toggled(bool newState)

    // What a flip asked for, shown until `checked` agrees or the backend has had a few
    // seconds: turning a radio on can take a while to report.
    property bool pending: false
    property bool requested: false
    readonly property bool on: root.pending ? root.requested : root.checked

    onCheckedChanged: if (root.checked === root.requested) root.pending = false

    Timer {
        id: pendingTimer
        interval: 4000
        onTriggered: root.pending = false
    }

    implicitWidth: 36
    implicitHeight: 20
    radius: height / 2
    opacity: enabled ? 1.0 : ThemeModule.Theme.disabledOpacity

    color: root.on
        ? root.activeColor
        : ThemeModule.Theme.alpha(ThemeModule.Theme.surface2, 0.4)
    border.width: ThemeModule.Theme.borderWidth
    border.color: root.on
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
    Accessible.checked: root.on
    Accessible.onPressAction: {
        if (root.enabled)
            root.flip();
    }

    function flip() {
        var next = !root.on;
        root.requested = next;
        root.pending = next !== root.checked;
        if (root.pending)
            pendingTimer.restart();
        Services.EffectsService.switched(root, next);
        root.toggled(next);
    }

    // Compact Thumb Handle
    Rectangle {
        id: thumb
        width: switchMouse.pressed ? 16 : 14
        height: 14
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.on ? (root.width - width - 3) : 3

        color: knob.status === Loader.Ready ? "transparent"
            : root.on ? ThemeModule.Theme.bg : ThemeModule.Theme.subtext

        Behavior on x {
            NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing }
        }

        Behavior on width {
            NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing }
        }

        Behavior on color {
            ColorAnimation { duration: ThemeModule.Theme.animDuration }
        }

        // The theme effects' knob, when they have one.
        Loader {
            id: knob
            anchors.centerIn: parent
            // EffectClock runs at this speed and frame rate.
            property real timeScale: 1
            property int frameRate: Services.EffectsService.frameRate
            width: parent.height
            height: parent.height
            sourceComponent: Services.EffectsService.knob
        }

        Binding { target: knob.item; property: "theme"; value: ThemeModule.Theme }
        Binding { target: knob.item; property: "pressed"; value: switchMouse.pressed }
        Binding { target: knob.item; property: "hovered"; value: switchMouse.containsMouse }
        Binding { target: knob.item; property: "checked"; value: root.on }
        Binding { target: knob.item; property: "travel"; value: thumb.x }
    }

    MouseArea {
        id: switchMouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.flip()
    }

    Components.Tooltip {
        visible: root.tooltipText !== "" && switchMouse.containsMouse
        text: root.tooltipText
        delay: root.tooltipDelay
    }
}
