pragma ComponentBehavior: Bound
// qmllint disable uncreatable-type unqualified unresolved-type
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

PanelWindow {
    id: root

    property bool shown: false
    property int displayedVolume: 0
    property bool displayedMuted: false
    property var targetScreen: null

    readonly property color indicatorColor: ThemeModule.Theme.accent
    readonly property string indicatorIcon: root.displayedMuted
        ? "audio-output-muted"
        : (root.displayedVolume <= 35 ? "audio-output-low" : "audio-output-high")

    function screenForMonitor(name) {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === name)
                return Quickshell.screens[i];
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function focusedScreen() {
        return Hyprland.focusedMonitor
            ? root.screenForMonitor(Hyprland.focusedMonitor.name)
            : root.screenForMonitor("");
    }

    function showState(volumePercent, muted) {
        root.targetScreen = root.focusedScreen();
        root.displayedVolume = Math.max(0, Math.min(100, Math.round(Number(volumePercent) || 0)));
        root.displayedMuted = !!muted;
        hideTimer.restart();
        exitAnimation.stop();

        if (!root.shown) {
            osdCard.opacity = 0;
            osdCard.scale = 0.96;
            root.shown = true;
            entranceAnimation.restart();
        } else {
            osdCard.opacity = 1;
            osdCard.scale = 1;
        }
    }

    screen: root.targetScreen
    visible: root.shown && root.targetScreen !== null
    implicitWidth: 316
    implicitHeight: 86
    color: "transparent"
    focusable: false
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore

    anchors {
        bottom: true
    }

    margins {
        bottom: 64
    }

    WlrLayershell.namespace: "speshell-volume-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Connections {
        target: Services.AudioService

        function onOutputOsdRequested(volumePercent, muted) {
            root.showState(volumePercent, muted);
        }
    }

    Timer {
        id: hideTimer
        interval: 1200
        repeat: false
        onTriggered: exitAnimation.restart()
    }

    ParallelAnimation {
        id: entranceAnimation

        NumberAnimation {
            target: osdCard
            property: "opacity"
            to: 1
            duration: ThemeModule.Theme.animDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: osdCard
            property: "scale"
            to: 1
            duration: ThemeModule.Theme.animDuration
            easing.type: Easing.OutBack
        }
    }

    NumberAnimation {
        id: exitAnimation
        target: osdCard
        property: "opacity"
        to: 0
        duration: 140
        easing.type: Easing.InCubic
        onStopped: {
            if (osdCard.opacity <= 0)
                root.shown = false;
        }
    }

    Rectangle {
        id: osdCard
        anchors.fill: parent
        radius: ThemeModule.Theme.borderRadius
        color: ThemeModule.Theme.card
        border.width: ThemeModule.Theme.borderWidth
        border.color: Qt.rgba(
            root.indicatorColor.r,
            root.indicatorColor.g,
            root.indicatorColor.b,
            0.48
        )
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 4
            color: root.indicatorColor
        }

        Row {
            anchors {
                fill: parent
                leftMargin: ThemeModule.Theme.spacingLarge
                rightMargin: ThemeModule.Theme.spacingLarge
                topMargin: ThemeModule.Theme.spacingMedium
                bottomMargin: ThemeModule.Theme.spacingMedium
            }
            spacing: ThemeModule.Theme.spacingMedium

            Rectangle {
                width: 46
                height: 46
                radius: ThemeModule.Theme.borderRadiusSmall
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(
                    root.indicatorColor.r,
                    root.indicatorColor.g,
                    root.indicatorColor.b,
                    0.14
                )

                Components.AppIcon {
                    anchors.centerIn: parent
                    name: root.indicatorIcon
                    size: 24
                    iconColor: root.indicatorColor
                }
            }

            Column {
                width: parent.width - 46 - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: ThemeModule.Theme.spacingSmall

                Row {
                    width: parent.width

                    Text {
                        text: root.displayedMuted ? "OUTPUT MUTED" : "OUTPUT VOLUME"
                        font.pixelSize: 10
                        font.family: ThemeModule.Theme.fontFamily
                        font.bold: true
                        font.letterSpacing: 1.2
                        color: ThemeModule.Theme.subtextBright
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Item { width: parent.width - parent.children[0].width - volumeValue.width; height: 1 }

                    Text {
                        id: volumeValue
                        text: root.displayedVolume + "%"
                        font.pixelSize: ThemeModule.Theme.fontSizeLarge
                        font.family: ThemeModule.Theme.fontFamily
                        font.bold: true
                        color: root.indicatorColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 1
                    color: ThemeModule.Theme.surface2
                    clip: true

                    Rectangle {
                        width: root.displayedMuted
                            ? 0
                            : parent.width * root.displayedVolume / 100
                        height: parent.height
                        radius: parent.radius
                        color: root.indicatorColor

                        Behavior on width {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }
}
