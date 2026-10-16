pragma ComponentBehavior: Bound
// qmllint disable uncreatable-type unqualified unresolved-type
import QtQuick
import Quickshell.Wayland
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

OsdWindow {
    id: root

    property int displayedVolume: 0
    property bool displayedMuted: false

    readonly property color indicatorColor: ThemeModule.Theme.accent
    readonly property string indicatorIcon: root.displayedMuted
        ? "audio-output-muted"
        : (root.displayedVolume <= 35 ? "audio-output-low" : "audio-output-high")

    card: osdCard
    implicitWidth: 316
    implicitHeight: 86

    anchors {
        bottom: true
    }

    // Quickshell's type info hides the fields of PanelWindow.margins.
    // qmllint disable missing-property
    margins {
        bottom: 64
    }
    // qmllint enable missing-property

    WlrLayershell.namespace: "speshell-volume-osd"

    Connections {
        target: Services.AudioService

        function onOutputOsdRequested(volumePercent, muted) {
            root.targetScreen = Services.DashboardService.focusedScreen();
            root.displayedVolume = Math.max(0, Math.min(100, Math.round(Number(volumePercent) || 0)));
            root.displayedMuted = !!muted;
            hideTimer.restart();
            root.present();
        }
    }

    Timer {
        id: hideTimer
        interval: 1200
        repeat: false
        onTriggered: root.dismiss()
    }

    Item {
        id: osdCard
        anchors.fill: parent

        // Bottom center of the screen: cut toward its center.
        Components.Surface {
            anchors.fill: parent
            cut: ThemeModule.Theme.spacingMedium
            cutTopLeft: true
            cutTopRight: true
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
                color: ThemeModule.Theme.alpha(root.indicatorColor, ThemeModule.Theme.tintSubtle)

                Components.AppIcon {
                    anchors.centerIn: parent
                    name: root.indicatorIcon
                    size: ThemeModule.Theme.iconSizeLarge
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
                        font.pixelSize: ThemeModule.Theme.fontSizeCaption
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
                                duration: ThemeModule.Theme.animDurationFast
                                easing.type: ThemeModule.Theme.animEasing
                            }
                        }
                    }
                }
            }
        }
    }
}
