pragma ComponentBehavior: Bound
// qmllint disable uncreatable-type

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

PanelWindow {
    id: root

    property bool active: false
    property bool focusGrabActive: false
    readonly property var targetScreen: root.focusedScreen()

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

    visible: root.active && root.targetScreen !== null
    screen: root.targetScreen
    color: "#111418"
    focusable: true
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "speshell-config-error"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    HyprlandFocusGrab {
        active: root.focusGrabActive
        windows: [root]
    }

    onVisibleChanged: {
        root.focusGrabActive = root.visible;
        if (root.visible)
            reportArea.forceActiveFocus();
    }

    Rectangle {
        anchors.fill: parent
        color: "#111418"

        Rectangle {
            id: errorCard
            anchors.centerIn: parent
            width: Math.min(720, parent.width - 48)
            height: Math.min(620, parent.height - 48)
            radius: 12
            color: "#1b2026"
            border.width: 1
            border.color: "#3a424c"

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                Row {
                    width: parent.width
                    spacing: 12

                    Components.AppIcon {
                        name: "alert"
                        size: 26
                        iconColor: "#ffb86c"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        width: parent.width - 38
                        spacing: 3

                        Text {
                            text: "Configuration invalid"
                            color: "#f4f7fa"
                            font.family: ThemeModule.Theme.fontFamily
                            font.pixelSize: 20
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            text: "Speshell is stopped until the configuration is corrected."
                            color: "#aeb8c4"
                            font.family: ThemeModule.Theme.fontFamily
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 6
                    color: "#15191e"
                    border.width: 1
                    border.color: "#303740"

                    Text {
                        anchors.fill: parent
                        anchors.margins: 10
                        text: Services.ConfigService.configPath || "~/.config/speshell/config.ini"
                        color: "#c6d0dc"
                        font.family: "monospace"
                        font.pixelSize: 11
                        elide: Text.ElideMiddle
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                ScrollView {
                    id: reportScroll
                    width: parent.width
                    height: Math.max(160, parent.height - 196)
                    clip: true

                    background: Rectangle {
                        radius: 8
                        color: "#12161a"
                        border.width: 1
                        border.color: "#303740"
                    }

                    TextArea {
                        id: reportArea
                        width: reportScroll.availableWidth
                        text: Services.ConfigService.errorReport
                        readOnly: true
                        selectByMouse: true
                        textFormat: Text.PlainText
                        wrapMode: TextEdit.Wrap
                        color: "#dde4ec"
                        selectionColor: "#4978a8"
                        selectedTextColor: "#ffffff"
                        font.family: "monospace"
                        font.pixelSize: 12
                        leftPadding: 14
                        rightPadding: 14
                        topPadding: 12
                        bottomPadding: 12
                        background: null
                    }
                }

                Item {
                    width: parent.width
                    height: 34

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(0, parent.width - actionRow.width - 12)
                        text: Services.ConfigService.operationMessage
                        color: Services.ConfigService.operationFailed ? "#ff8080" : "#7bd9a5"
                        font.family: ThemeModule.Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    Row {
                        id: actionRow
                        anchors.right: parent.right
                        spacing: 8

                        Components.ActionButton {
                            label: "Quit"
                            iconName: "close"
                            toneColor: "#aeb8c4"
                            onActivated: Qt.quit()
                        }

                        Components.ActionButton {
                            label: "Open config"
                            iconName: "folder-open"
                            toneColor: "#7eb6e8"
                            onActivated: Services.ConfigService.openConfig()
                        }

                        Components.ActionButton {
                            label: "Copy report"
                            iconName: "copy"
                            toneColor: "#7eb6e8"
                            onActivated: Services.ConfigService.copyErrorReport()
                        }

                        Components.ActionButton {
                            label: "Retry"
                            iconName: "refresh"
                            toneColor: "#7bd9a5"
                            onActivated: Services.ConfigService.load()
                        }
                    }
                }
            }
        }
    }
}
