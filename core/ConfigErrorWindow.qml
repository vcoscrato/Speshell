pragma ComponentBehavior: Bound
// qmllint disable uncreatable-type

import QtQuick
import QtQuick.Templates as T
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
    readonly property var targetScreen: Services.DashboardService.focusedScreen()

    visible: root.active && root.targetScreen !== null
    screen: root.targetScreen
    color: ThemeModule.Theme.crust
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

    // The palette of the last theme applied, or Cosmos's before any.
    Components.Surface {
        anchors.centerIn: parent
        width: Math.min(720, parent.width - ThemeModule.Theme.spacingXL * 2)
        height: Math.min(620, parent.height - ThemeModule.Theme.spacingXL * 2)
        cutTopRight: true
        cutBottomLeft: true
        edge: "left"
        edgeColor: ThemeModule.Theme.error

        Column {
            anchors.fill: parent
            anchors.margins: ThemeModule.Theme.spacingXL
            spacing: ThemeModule.Theme.spacingLarge

            Row {
                width: parent.width
                spacing: ThemeModule.Theme.spacingMedium

                Components.AppIcon {
                    id: alertIcon
                    name: "alert"
                    size: ThemeModule.Theme.iconSizeLarge
                    iconColor: ThemeModule.Theme.error
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    width: parent.width - alertIcon.width - parent.spacing
                    spacing: ThemeModule.Theme.spacingMicro

                    Text {
                        text: "Configuration invalid"
                        color: ThemeModule.Theme.text
                        font.family: ThemeModule.Theme.fontFamily
                        font.pixelSize: ThemeModule.Theme.fontSizeTitle
                        font.bold: true
                    }

                    Text {
                        width: parent.width
                        text: "Speshell is stopped until the configuration is corrected."
                        color: ThemeModule.Theme.subtext
                        font.family: ThemeModule.Theme.fontFamily
                        font.pixelSize: ThemeModule.Theme.fontSizeSupporting
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: ThemeModule.Theme.controlHeight
                radius: ThemeModule.Theme.borderRadius
                color: ThemeModule.Theme.mantle
                border.width: ThemeModule.Theme.borderWidth
                border.color: ThemeModule.Theme.controlBorder

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: ThemeModule.Theme.spacingMedium
                    anchors.rightMargin: ThemeModule.Theme.spacingMedium
                    text: Services.ConfigService.configPath || "~/.config/speshell/config.ini"
                    color: ThemeModule.Theme.subtextBright
                    font.family: "monospace"
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    elide: Text.ElideMiddle
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                width: parent.width
                height: Math.max(160, parent.height - 196)
                radius: ThemeModule.Theme.borderRadius
                color: ThemeModule.Theme.mantle
                border.width: ThemeModule.Theme.borderWidth
                border.color: ThemeModule.Theme.controlBorder

                Flickable {
                    id: reportScroll
                    anchors.fill: parent
                    anchors.margins: ThemeModule.Theme.borderWidth
                    contentHeight: reportArea.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    T.ScrollBar.vertical: Components.StyledScrollBar {
                        policy: reportScroll.contentHeight > reportScroll.height ? T.ScrollBar.AsNeeded : T.ScrollBar.AlwaysOff
                    }

                    TextEdit {
                        id: reportArea
                        width: reportScroll.width
                        padding: ThemeModule.Theme.spacingMedium
                        text: Services.ConfigService.errorReport
                        readOnly: true
                        selectByMouse: true
                        textFormat: TextEdit.PlainText
                        wrapMode: TextEdit.Wrap
                        color: ThemeModule.Theme.text
                        selectionColor: ThemeModule.Theme.accent
                        selectedTextColor: ThemeModule.Theme.bg
                        font.family: "monospace"
                        font.pixelSize: ThemeModule.Theme.fontSizeSupporting
                    }
                }
            }

            Item {
                width: parent.width
                height: ThemeModule.Theme.controlHeight

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, parent.width - actionRow.width - ThemeModule.Theme.spacingMedium)
                    text: Services.ConfigService.operationMessage
                    color: Services.ConfigService.operationFailed ? ThemeModule.Theme.error : ThemeModule.Theme.success
                    font.family: ThemeModule.Theme.fontFamily
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    elide: Text.ElideRight
                }

                Row {
                    id: actionRow
                    anchors.right: parent.right
                    spacing: ThemeModule.Theme.spacingSmall

                    Components.ActionButton {
                        label: "Quit"
                        iconName: "close"
                        toneColor: ThemeModule.Theme.subtext
                        onActivated: Qt.quit()
                    }

                    Components.ActionButton {
                        label: "Open config"
                        iconName: "folder-open"
                        toneColor: ThemeModule.Theme.toneColor("info")
                        onActivated: Services.ConfigService.openConfig()
                    }

                    Components.ActionButton {
                        label: "Copy report"
                        iconName: "copy"
                        toneColor: ThemeModule.Theme.toneColor("info")
                        onActivated: Services.ConfigService.copyErrorReport()
                    }

                    Components.ActionButton {
                        label: "Retry"
                        iconName: "refresh"
                        toneColor: ThemeModule.Theme.success
                        onActivated: Services.ConfigService.load()
                    }
                }
            }
        }
    }
}
