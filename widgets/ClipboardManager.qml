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
    property string query: ""

    readonly property var history: Services.ClipboardService.history
    readonly property var shownHistory: {
        var needle = root.query.trim().toLowerCase();
        if (needle === "")
            return root.history;
        return root.history.filter(function(entry) {
            return entry.preview.toLowerCase().indexOf(needle) >= 0;
        });
    }

    onPresentedChanged: {
        Services.ClipboardService.setViewPresented(root.presented);
        if (!root.presented)
            root.query = "";
    }
    Component.onCompleted: Services.ClipboardService.setViewPresented(root.presented)
    Component.onDestruction: Services.ClipboardService.setViewPresented(false)

    headerActions: Components.IconButton {
        iconName: "trash"
        iconSize: ThemeModule.Theme.iconSizeSmall
        size: ThemeModule.Theme.controlHeightSmall
        iconColor: ThemeModule.Theme.subtextBright
        visible: root.history.length > 0
        tooltipText: "Clear clipboard history"
        onClicked: Services.ClipboardService.clearHistory()
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Rectangle {
            width: parent.width
            height: ThemeModule.Theme.controlHeight
            visible: root.history.length > 0
            radius: ThemeModule.Theme.borderRadiusSmall
            color: ThemeModule.Theme.controlFill
            border.width: ThemeModule.Theme.borderWidth
            border.color: searchInput.activeFocus ? ThemeModule.Theme.selectedBorder : ThemeModule.Theme.controlBorder

            Components.AppIcon {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: ThemeModule.Theme.spacingSmall
                anchors.verticalCenter: parent.verticalCenter
                name: "search"
                size: ThemeModule.Theme.iconSizeSmall
                iconColor: searchInput.activeFocus ? ThemeModule.Theme.accent : ThemeModule.Theme.subtext
            }

            TextInput {
                id: searchInput
                anchors.left: searchIcon.right
                anchors.leftMargin: ThemeModule.Theme.spacingSmall
                anchors.right: clearSearch.visible ? clearSearch.left : parent.right
                anchors.rightMargin: ThemeModule.Theme.spacingSmall
                anchors.verticalCenter: parent.verticalCenter
                text: root.query
                color: ThemeModule.Theme.text
                selectionColor: ThemeModule.Theme.accent
                selectedTextColor: ThemeModule.Theme.bg
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                clip: true
                onTextEdited: root.query = text
                Keys.onEscapePressed: function(event) {
                    if (root.query === "") {
                        event.accepted = false;
                        return;
                    }
                    root.query = "";
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Services.ClipboardService.loading
                        ? "Loading…"
                        : "Search " + root.history.length + (root.history.length === 1 ? " item" : " items")
                    color: ThemeModule.Theme.overlay
                    font: searchInput.font
                    visible: searchInput.text === "" && !searchInput.preeditText
                }
            }

            Components.IconButton {
                id: clearSearch
                anchors.right: parent.right
                anchors.rightMargin: ThemeModule.Theme.spacingTiny
                anchors.verticalCenter: parent.verticalCenter
                visible: root.query !== ""
                iconName: "close"
                iconSize: ThemeModule.Theme.iconSizeTiny
                size: ThemeModule.Theme.controlHeightSmall
                iconColor: ThemeModule.Theme.subtext
                tooltipText: "Clear search"
                onClicked: root.query = ""
            }
        }

        Text {
            width: parent.width
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
            visible: text !== ""
        }

        Column {
            id: clipboardRows
            width: parent.width
            spacing: ThemeModule.Theme.spacingTiny

            Repeater {
                model: root.shownHistory

                delegate: Rectangle {
                    id: clipRow
                    required property var modelData
                    readonly property bool image: clipRow.modelData.kind === "image"
                    readonly property bool lastCopied: clipRow.modelData.id === Services.ClipboardService.lastCopiedId

                    width: clipboardRows.width
                    height: clipRow.image
                        ? thumbnailFrame.height + ThemeModule.Theme.spacingSmall * 2
                        : Math.max(ThemeModule.Theme.controlHeight + ThemeModule.Theme.spacingSmall,
                            previewText.implicitHeight + ThemeModule.Theme.spacingSmall * 2)
                    radius: ThemeModule.Theme.borderRadiusSmall
                    color: clipMouse.containsMouse
                        ? ThemeModule.Theme.cardHover
                        : (clipRow.lastCopied ? ThemeModule.Theme.selectedFill : ThemeModule.Theme.controlFill)
                    border.width: ThemeModule.Theme.borderWidth
                    border.color: clipRow.lastCopied ? ThemeModule.Theme.selectedBorder : ThemeModule.Theme.controlBorder

                    Accessible.role: Accessible.Button
                    Accessible.name: "Copy clipboard item"
                    Accessible.description: clipRow.modelData.preview
                    Accessible.onPressAction: Services.ClipboardService.copyEntry(clipRow.modelData)

                    Rectangle {
                        id: thumbnailFrame
                        visible: clipRow.image
                        anchors.left: parent.left
                        anchors.leftMargin: ThemeModule.Theme.spacingSmall
                        anchors.verticalCenter: parent.verticalCenter
                        width: 112
                        height: 64
                        radius: ThemeModule.Theme.borderRadiusSmall
                        color: ThemeModule.Theme.crust
                        clip: true

                        Image {
                            id: thumbnail
                            anchors.fill: parent
                            source: clipRow.modelData.thumbnail ? "file://" + clipRow.modelData.thumbnail : ""
                            sourceSize: Qt.size(224, 128)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                        }

                        Components.AppIcon {
                            anchors.centerIn: parent
                            visible: thumbnail.status !== Image.Ready
                            name: "photo"
                            size: ThemeModule.Theme.iconSizeMedium
                            iconColor: ThemeModule.Theme.overlay
                        }
                    }

                    Text {
                        id: previewText
                        anchors.left: clipRow.image ? thumbnailFrame.right : parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: clipRow.image ? ThemeModule.Theme.spacingMedium : ThemeModule.Theme.spacingSmall
                        anchors.rightMargin: ThemeModule.Theme.spacingSmall
                        text: clipRow.modelData.preview
                        font.pixelSize: clipRow.image ? ThemeModule.Theme.fontSizeCaption : ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        color: clipRow.image || clipRow.modelData.kind === "binary"
                            ? ThemeModule.Theme.subtext
                            : (clipRow.modelData.kind === "link" ? ThemeModule.Theme.accent : ThemeModule.Theme.text)
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        maximumLineCount: 2
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

        Components.EmptyState {
            visible: !Services.ClipboardService.loading && root.shownHistory.length === 0
            iconName: root.history.length > 0 ? "search" : "clipboard"
            title: !Services.ClipboardService.available
                ? "Clipboard history is off"
                : (root.history.length > 0 ? "No matches" : "Nothing copied yet")
            detail: !Services.ClipboardService.available
                ? "Install cliphist and wl-clipboard to keep a history."
                : (root.history.length > 0 ? "Nothing copied matches “" + root.query.trim() + "”."
                    : "Text and images you copy show up here.")
        }
    }
}
