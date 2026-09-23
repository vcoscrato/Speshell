pragma ComponentBehavior: Bound
import QtQuick
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Clipboard"
    iconName: "clipboard"

    property bool presented: false

    onPresentedChanged: Services.ClipboardService.setViewPresented(root.presented)
    Component.onCompleted: Services.ClipboardService.setViewPresented(root.presented)
    Component.onDestruction: Services.ClipboardService.setViewPresented(false)

    headerActions: Components.IconButton {
        iconName: "trash"
        iconSize: ThemeModule.Theme.iconSizeSmall
        size: ThemeModule.Theme.controlHeightSmall
        iconColor: ThemeModule.Theme.subtextBright
        visible: Services.ClipboardService.history.length > 0
        tooltipText: "Clear clipboard history"
        onClicked: Services.ClipboardService.clearHistory()
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Text {
            width: parent.width
            text: Services.ClipboardService.loading
                ? "Loading..."
                : (Services.ClipboardService.history.length > 0
                    ? Services.ClipboardService.history.length + " items"
                    : "")
            font.pixelSize: ThemeModule.Theme.fontSizeCaption
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.subtext
            visible: text !== ""
            elide: Text.ElideRight
        }

        Rectangle {
            width: parent.width
            height: 18
            radius: 9
            color: "transparent"
            visible: Services.ClipboardService.feedbackText !== ""

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Services.ClipboardService.feedbackText
                font.pixelSize: ThemeModule.Theme.fontSizeCaption
                font.family: ThemeModule.Theme.fontFamily
                color: {
                    if (Services.ClipboardService.feedbackTone === "success") return ThemeModule.Theme.success;
                    if (Services.ClipboardService.feedbackTone === "warning") return ThemeModule.Theme.warning;
                    if (Services.ClipboardService.feedbackTone === "error") return ThemeModule.Theme.error;
                    return ThemeModule.Theme.subtext;
                }
                elide: Text.ElideRight
                width: parent.width
            }
        }

        Column {
            id: clipboardRows
            width: parent.width
            spacing: ThemeModule.Theme.spacingTiny

            Repeater {
                model: Services.ClipboardService.history

                delegate: Rectangle {
                    id: clipRow
                    required property var modelData

                    width: clipboardRows.width
                    height: Math.max(40, previewText.implicitHeight + ThemeModule.Theme.spacingSmall * 2)
                    radius: ThemeModule.Theme.borderRadiusSmall
                    color: clipMouse.containsMouse
                        ? ThemeModule.Theme.cardHover
                        : (clipRow.modelData.id === Services.ClipboardService.lastCopiedId
                            ? ThemeModule.Theme.selectedFill
                            : ThemeModule.Theme.controlFill)
                    border.width: ThemeModule.Theme.borderWidth
                    border.color: clipRow.modelData.id === Services.ClipboardService.lastCopiedId
                        ? ThemeModule.Theme.selectedBorder
                        : ThemeModule.Theme.controlBorder

                    Accessible.role: Accessible.Button
                    Accessible.name: "Copy clipboard item"
                    Accessible.description: clipRow.modelData.preview
                    Accessible.onPressAction: Services.ClipboardService.copyEntry(clipRow.modelData)

                    Text {
                        id: previewText
                        anchors.fill: parent
                        anchors.margins: ThemeModule.Theme.spacingSmall
                        text: clipRow.modelData.preview
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.text
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        maximumLineCount: 3
                    }

                    MouseArea {
                        id: clipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.ClipboardService.copyEntry(clipRow.modelData)
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Services.ClipboardService.available
                ? "Nothing copied yet."
                : "Install and run cliphist to enable clipboard history."
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.subtext
            visible: Services.ClipboardService.history.length === 0 && !Services.ClipboardService.loading
        }
    }
}
