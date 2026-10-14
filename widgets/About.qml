pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root

    property string quickShellVersion: ""
    property string hyprlandVersion: ""

    title: "About"
    iconName: "info"

    readonly property string configDisplayPath: {
        var path = Services.ConfigService.configPath
            || (Services.ConfigService.configDir || "~/.config/speshell") + "/config.ini";
        var home = String(Quickshell.env("HOME") || "");
        return home !== "" && path.indexOf(home) === 0 ? "~" + path.substring(home.length) : path;
    }

    readonly property real labelWidth: Math.ceil(Math.max(
        labelMetrics.advanceWidth("QuickShell"),
        labelMetrics.advanceWidth("Hyprland"),
        labelMetrics.advanceWidth("Config")))

    FontMetrics {
        id: labelMetrics
        font.pixelSize: ThemeModule.Theme.fontSizeSmall
        font.family: ThemeModule.Theme.fontFamily
    }

    // A label and its value.
    component Detail: Item {
        id: detail

        property string label: ""
        property string value: ""
        property string info: ""
        property real labelWidth: 0

        width: parent ? parent.width : 0
        height: Math.max(ThemeModule.Theme.controlHeightSmall, valueText.implicitHeight)

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: detail.labelWidth
            text: detail.label
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.overlay
        }

        Text {
            id: valueText
            anchors.left: parent.left
            anchors.leftMargin: detail.labelWidth + ThemeModule.Theme.spacingLarge
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, detail.width - x
                - (detailInfo.visible ? detailInfo.width + ThemeModule.Theme.spacingSmall : 0))
            text: detail.value
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.text
            elide: Text.ElideMiddle
        }

        Components.InfoTip {
            id: detailInfo
            anchors.left: valueText.right
            anchors.verticalCenter: parent.verticalCenter
            visible: detail.info !== ""
            text: detail.info
        }
    }

    headerActions: Components.IconButton {
        anchors.verticalCenter: parent.verticalCenter
        size: ThemeModule.Theme.controlHeightSmall
        iconSize: ThemeModule.Theme.iconSizeSmall
        iconName: "github"
        iconColor: containsMouse ? ThemeModule.Theme.accent : ThemeModule.Theme.subtext
        tooltipText: "View Speshell on GitHub"
        onClicked: Qt.openUrlExternally("https://github.com/vcoscrato/speshell")
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingLarge

        Row {
            spacing: ThemeModule.Theme.spacingMedium

            Components.SpeshellMark {
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: nameText
                anchors.verticalCenter: parent.verticalCenter
                text: "Speshell"
                font.pixelSize: ThemeModule.Theme.fontSizeLarge
                font.family: ThemeModule.Theme.fontFamily
                font.bold: true
                color: ThemeModule.Theme.text
            }

            Text {
                anchors.baseline: nameText.baseline
                text: Services.SystemState.appVersion
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext
            }
        }

        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingTiny

            Detail {
                labelWidth: root.labelWidth
                label: "QuickShell"
                value: root.quickShellVersion || "unknown"
            }

            Detail {
                labelWidth: root.labelWidth
                label: "Hyprland"
                value: root.hyprlandVersion || "unknown"
            }

            Detail {
                labelWidth: root.labelWidth
                label: "Config"
                value: root.configDisplayPath
                info: "A few options, like custom ! shortcuts and device names, are only in this file. "
                    + "Saved changes apply right away."
            }

            // Under the path, aligned with the values.
            Row {
                x: root.labelWidth + ThemeModule.Theme.spacingLarge
                spacing: ThemeModule.Theme.spacingTiny

                Components.InlineActionChip {
                    text: "Edit"
                    iconName: "notes"
                    enabled: !Services.ConfigService.savingConfig
                    onActivated: Services.ConfigService.openConfig()
                }

                Components.InlineActionChip {
                    text: Services.ConfigService.loading ? "Loading" : "Reload"
                    iconName: "refresh"
                    enabled: !Services.ConfigService.loading && !Services.ConfigService.savingConfig
                    onActivated: Services.ConfigService.load()
                }

                Components.InlineActionChip {
                    text: Services.SystemState.relaunching ? "Starting" : "Relaunch"
                    iconName: "restart"
                    enabled: Services.SystemState.canRelaunch
                    onActivated: Services.SystemState.relaunch()
                }
            }
        }

        Text {
            visible: Services.ConfigService.operationFailed && Services.ConfigService.operationMessage !== ""
            width: parent.width
            text: Services.ConfigService.operationMessage
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.error
            wrapMode: Text.Wrap
        }

        // Setup problems worth fixing; nothing when the setup is complete.
        Repeater {
            model: Services.FeatureSupport.issues

            delegate: Row {
                id: issueRow

                required property var modelData

                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Components.AppIcon {
                    name: "alert"
                    size: ThemeModule.Theme.iconSizeSmall
                    iconColor: ThemeModule.Theme.warning
                }

                Column {
                    width: parent.width - ThemeModule.Theme.iconSizeSmall - parent.spacing
                    spacing: ThemeModule.Theme.spacingMicro

                    Text {
                        text: issueRow.modelData.title
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        font.bold: true
                        color: ThemeModule.Theme.text
                    }

                    Text {
                        width: parent.width
                        text: issueRow.modelData.detail
                        font.pixelSize: ThemeModule.Theme.fontSizeCaption
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.subtext
                        wrapMode: Text.Wrap
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
