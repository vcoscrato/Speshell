pragma ComponentBehavior: Bound

import QtQuick
import "../theme" as ThemeModule
import "." as Components

// A device or network: an icon disc, a title over a detail line, and action chips.
// `current` marks the active connection; `busy` spins the icon while it changes.
Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property color subtitleColor: ThemeModule.Theme.subtext
    property string iconName: ""
    property bool current: false
    property bool busy: false
    property bool primaryEnabled: true
    property var actionChips: [] // [{text, tone, enabled, actionId}]

    default property alias expandedContent: expandedColumn.data

    signal primaryTriggered()
    signal actionTriggered(string actionId)

    // The spinner stops wherever it is; set the icon upright again.
    onBusyChanged: if (!root.busy) statusIcon.rotation = 0

    width: parent ? parent.width : 300
    implicitHeight: contentColumn.implicitHeight + ThemeModule.Theme.spacingSmall * 2
    radius: ThemeModule.Theme.borderRadiusSmall
    color: root.current
        ? ThemeModule.Theme.selectedFill
        : (rowMouse.containsMouse && root.primaryEnabled ? ThemeModule.Theme.controlFill : "transparent")
    border.width: ThemeModule.Theme.borderWidth
    border.color: root.current ? ThemeModule.Theme.selectedBorder : "transparent"

    Accessible.role: Accessible.Button
    Accessible.name: root.title
    Accessible.description: root.subtitle
    Accessible.onPressAction: if (root.primaryEnabled) root.primaryTriggered()

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.primaryEnabled
        cursorShape: root.primaryEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.primaryTriggered()
    }

    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: ThemeModule.Theme.spacingSmall
        spacing: ThemeModule.Theme.spacingSmall

        Item {
            width: parent.width
            height: Math.max(iconDisc.height, textColumn.implicitHeight)

            Rectangle {
                id: iconDisc
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: ThemeModule.Theme.controlHeight
                height: width
                radius: width / 2
                color: ThemeModule.Theme.alpha(root.current ? ThemeModule.Theme.accent : ThemeModule.Theme.overlay,
                    root.current ? ThemeModule.Theme.tintStrong : ThemeModule.Theme.tintSubtle)

                Components.AppIcon {
                    id: statusIcon
                    anchors.centerIn: parent
                    name: root.busy ? "loader" : root.iconName
                    size: ThemeModule.Theme.iconSizeMedium
                    iconColor: root.current || root.busy ? ThemeModule.Theme.accent : ThemeModule.Theme.subtextBright

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 1200
                        loops: Animation.Infinite
                        running: root.busy && root.visible
                    }
                }
            }

            Column {
                id: textColumn
                anchors.left: iconDisc.right
                anchors.leftMargin: ThemeModule.Theme.spacingMedium
                anchors.right: chipRow.left
                anchors.rightMargin: chipRow.width > 0 ? ThemeModule.Theme.spacingSmall : 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: ThemeModule.Theme.spacingMicro

                Text {
                    width: parent.width
                    text: root.title
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    font.family: ThemeModule.Theme.fontFamily
                    font.weight: root.current ? Font.DemiBold : Font.Medium
                    color: ThemeModule.Theme.text
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.subtitle
                    font.pixelSize: ThemeModule.Theme.fontSizeCaption
                    font.family: ThemeModule.Theme.fontFamily
                    color: root.subtitleColor
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }

            Row {
                id: chipRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: ThemeModule.Theme.spacingTiny

                Repeater {
                    model: root.actionChips
                    delegate: Components.InlineActionChip {
                        id: chip
                        required property var modelData
                        text: chip.modelData.text || ""
                        tone: chip.modelData.tone || "neutral"
                        enabled: chip.modelData.enabled !== false
                        onActivated: root.actionTriggered(chip.modelData.actionId || "")
                    }
                }
            }
        }

        Column {
            id: expandedColumn
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
        }
    }
}
