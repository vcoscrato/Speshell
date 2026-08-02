import QtQuick
import Quickshell.Io
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root

    property string quickShellVersion: ""
    property string hyprlandVersion: ""

    function availability(available) {
        return available ? "Available" : "Unavailable";
    }

    function systemRows() {
        return [
            { label: "Bluetooth", value: root.availability(Services.FeatureSupport.supportsBluetooth) },
            { label: "Brightness", value: root.availability(Services.FeatureSupport.supportsBrightness) },
            { label: "Backlight", value: Services.FeatureSupport.backlightDeviceName || "Unavailable" }
        ];
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium

        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall

            Row {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Text {
                    width: 82
                    text: "Speshell"
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    font.family: ThemeModule.Theme.fontFamily
                    font.bold: true
                    color: ThemeModule.Theme.text
                }

                Item {
                    width: parent.width - 82 - ThemeModule.Theme.spacingSmall
                    height: Math.max(versionText.implicitHeight, githubButton.height)

                    Text {
                        id: versionText

                        anchors.left: parent.left
                        anchors.right: githubButton.left
                        anchors.rightMargin: ThemeModule.Theme.spacingTiny
                        anchors.verticalCenter: parent.verticalCenter
                        text: Services.SystemState.appVersion
                        font.pixelSize: ThemeModule.Theme.fontSizeNormal
                        font.family: ThemeModule.Theme.fontFamily
                        font.bold: true
                        color: ThemeModule.Theme.accent
                        elide: Text.ElideRight
                    }

                    Components.IconButton {
                        id: githubButton

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        size: 28
                        iconSize: 17
                        iconName: "github"
                        iconColor: containsMouse
                            ? ThemeModule.Theme.accent
                            : ThemeModule.Theme.text
                        tooltipText: "View Speshell on GitHub"
                        onClicked: Qt.openUrlExternally("https://github.com/vcoscrato/Speshell")
                    }
                }
            }

            Row {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Text {
                    width: 82
                    text: "QuickShell"
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.subtext
                }

                Text {
                    width: parent.width - 82 - ThemeModule.Theme.spacingSmall
                    text: root.quickShellVersion !== "" ? root.quickShellVersion : "Unknown"
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.text
                    wrapMode: Text.WrapAnywhere
                }
            }

            Row {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Text {
                    width: 82
                    text: "Hyprland"
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.subtext
                }

                Text {
                    width: parent.width - 82 - ThemeModule.Theme.spacingSmall
                    text: root.hyprlandVersion !== "" ? root.hyprlandVersion : "Unknown"
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.text
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        Text {
            text: "SYSTEM CAPABILITIES"
            font.pixelSize: 9
            font.family: ThemeModule.Theme.fontFamily
            font.bold: true
            font.letterSpacing: 0.8
            color: ThemeModule.Theme.overlay
        }

        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall

            Repeater {
                model: root.systemRows()

                delegate: Row {
                    id: systemRow

                    required property var modelData

                    width: parent.width
                    spacing: ThemeModule.Theme.spacingSmall

                    Text {
                        width: 82
                        text: systemRow.modelData.label
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.subtext
                    }

                    Text {
                        width: parent.width - 82 - ThemeModule.Theme.spacingSmall
                        text: systemRow.modelData.value
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.text
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }
    }

    Process {
        id: quickshellVersionProc
        command: ["quickshell", "--version"]
        running: false

        stdout: SplitParser {
            onRead: function(line) {
                var match = String(line || "").match(/^Quickshell\s+(\S+)/i);
                if (match)
                    root.quickShellVersion = match[1];
            }
        }
    }

    Process {
        id: hyprlandVersionProc
        command: ["hyprctl", "version"]
        running: false

        stdout: SplitParser {
            onRead: function(line) {
                if (root.hyprlandVersion !== "")
                    return;
                var match = String(line || "").match(/^Hyprland\s+(\S+)/);
                if (match)
                    root.hyprlandVersion = match[1];
            }
        }
    }

    Component.onCompleted: {
        quickshellVersionProc.running = true;
        hyprlandVersionProc.running = true;
    }
}
