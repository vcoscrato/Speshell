pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Notes"
    iconName: "notes"

    property bool dashboardActive: true
    property bool syncingFromService: false
    readonly property int minimumEditorLines: 4
    readonly property int maximumEditorLines: 14
    readonly property int editorPadding: ThemeModule.Theme.spacingSmall
    readonly property int editorScrollbarInset: ThemeModule.Theme.spacingMedium
    readonly property real editorMinimumHeight: Math.ceil(notesFontMetrics.lineSpacing * minimumEditorLines + editorPadding * 2)
    readonly property real editorMaximumHeight: Math.ceil(notesFontMetrics.lineSpacing * maximumEditorLines + editorPadding * 2)
    readonly property real editorPreferredHeight: notesInput.implicitHeight + editorPadding * 2

    function syncFromService() {
        if (notesInput.text === Services.NotesService.text)
            return;

        root.syncingFromService = true;
        notesInput.text = Services.NotesService.text;
        root.syncingFromService = false;
    }

    onDashboardActiveChanged: {
        if (root.dashboardActive)
            Services.NotesService.read();
        else
            Services.NotesService.flush(false);
    }

    Component.onCompleted: {
        Services.NotesService.read();
        root.syncFromService();
    }
    Component.onDestruction: Services.NotesService.flush(true)

    Connections {
        target: Services.NotesService
        function onTextChanged() {
            root.syncFromService();
        }
    }

    headerActions: Components.IconButton {
        id: copyNotesButton
        size: 24
        iconName: "copy"
        iconSize: 15
        iconColor: enabled ? ThemeModule.Theme.subtextBright : ThemeModule.Theme.overlay
        enabled: Services.NotesService.loaded && notesInput.text !== ""
        tooltipText: "Copy notes"
        onClicked: Services.ClipboardService.copyText(notesInput.text)
    }

    Text {
        width: parent.width
        visible: Services.NotesService.errorText !== ""
        text: Services.NotesService.errorText
        color: ThemeModule.Theme.error
        font.family: ThemeModule.Theme.fontFamily
        font.pixelSize: ThemeModule.Theme.fontSizeSmall
    }

    FontMetrics {
        id: notesFontMetrics
        font.family: ThemeModule.Theme.fontFamily
        font.pixelSize: ThemeModule.Theme.fontSizeSmall
    }

    Rectangle {
        width: parent.width
        height: Math.min(root.editorMaximumHeight, Math.max(root.editorMinimumHeight, root.editorPreferredHeight))
        radius: ThemeModule.Theme.borderRadiusSmall
        color: Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.22)
        border.width: 1
        border.color: notesInput.activeFocus
            ? ThemeModule.Theme.accent
            : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.24)

        Flickable {
            id: notesFlickable
            anchors.fill: parent
            anchors.margins: root.editorPadding
            readonly property bool needsVerticalScroll: contentHeight > height + 1
            readonly property int scrollbarInset: root.editorScrollbarInset
            contentWidth: Math.max(0, width - scrollbarInset)
            contentHeight: Math.max(notesInput.implicitHeight, height)
            clip: true

            ScrollBar.vertical: ScrollBar {
                policy: notesFlickable.needsVerticalScroll ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            }

            TextArea {
                id: notesInput
                width: notesFlickable.contentWidth
                height: notesFlickable.contentHeight
                wrapMode: TextEdit.Wrap
                background: null
                topPadding: 0
                bottomPadding: 0
                leftPadding: 0
                rightPadding: 0
                placeholderText: "Keep notes, prompts, commands, or text you want nearby."
                color: ThemeModule.Theme.text
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                enabled: Services.NotesService.loaded
                onTextChanged: {
                    if (!root.syncingFromService)
                        Services.NotesService.setText(text);
                }
                onActiveFocusChanged: {
                    if (!activeFocus)
                        Services.NotesService.flush(false);
                }
            }
        }
    }
}
