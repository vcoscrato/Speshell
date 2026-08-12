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
        id: clearButton
        iconName: "trash"
        iconSize: 14
        size: 24
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
            font.pixelSize: 10
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
                font.pixelSize: 10
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
                    height: Math.max(40, previewText.implicitHeight + 16)
                    radius: ThemeModule.Theme.borderRadiusSmall
                    activeFocusOnTab: true
                    color: clipMouse.containsMouse
                        ? ThemeModule.Theme.cardHover
                        : (clipRow.modelData.id === Services.ClipboardService.lastCopiedId
                            ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.12)
                            : Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.10))
                    border.width: clipRow.activeFocus ? 2 : 1
                    border.color: clipRow.activeFocus
                        ? ThemeModule.Theme.accent
                        : (clipRow.modelData.id === Services.ClipboardService.lastCopiedId
                        ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.45)
                        : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.18))

                    Accessible.role: Accessible.Button
                    Accessible.name: "Copy clipboard item"
                    Accessible.description: clipRow.modelData.preview
                    Accessible.onPressAction: Services.ClipboardService.copyEntry(clipRow.modelData)

                    Keys.onPressed: function(event) {
                        if (event.isAutoRepeat)
                            return;
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                            Services.ClipboardService.copyEntry(clipRow.modelData);
                            event.accepted = true;
                        }
                    }

                    Text {
                        id: previewText
                        anchors.fill: parent
                        anchors.margins: 8
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
                        onClicked: {
                            clipRow.forceActiveFocus();
                            Services.ClipboardService.copyEntry(clipRow.modelData);
                        }
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
