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
    property bool previewMode: true
    property bool creatingNote: false
    property string renderedMarkdown: ""

    readonly property int minimumEditorLines: 8
    readonly property int maximumEditorLines: 22
    readonly property int editorPadding: ThemeModule.Theme.spacingSmall
    readonly property int editorScrollbarInset: ThemeModule.Theme.spacingMedium
    readonly property real editorMinimumHeight: Math.ceil(notesFontMetrics.lineSpacing * minimumEditorLines + editorPadding * 2)
    readonly property real editorMaximumHeight: Math.ceil(notesFontMetrics.lineSpacing * maximumEditorLines + editorPadding * 2)
    readonly property real editorPreferredHeight: (root.previewMode
        ? markdownText.implicitHeight
        : notesInput.implicitHeight) + editorPadding * 2
    readonly property bool canDeleteNote: Services.NotesService.noteList.length > 1
        && Services.NotesService.pendingDeleteNote === ""
        && Services.NotesService.managementEnabled

    Item {
        id: focusSink
        focus: true
    }

    function updateRenderedMarkdown() {
        var src = notesInput.text;
        if (!src || src.trim() === "") {
            root.renderedMarkdown = "*No note content. Click anywhere in box to add notes.*";
            return;
        }
        var str = String(src);

        // Subscripts: $X_1$ or $X_{12}$
        str = str.replace(/\$([a-zA-Z0-9]+)_\{?([a-zA-Z0-9+\-=]+)\}?\$/g, "$1<sub>$2</sub>");
        // Superscripts: $X^2$ or $X^{12}$
        str = str.replace(/\$([a-zA-Z0-9]+)\^\{?([a-zA-Z0-9+\-=]+)\}?\$/g, "$1<sup>$2</sup>");
        // Simple standalone X_1 or X^2 outside formulas
        str = str.replace(/\b([a-zA-Z])_([0-9a-zA-Z])\b/g, "$1<sub>$2</sub>");
        str = str.replace(/\b([a-zA-Z])\^([0-9a-zA-Z])\b/g, "$1<sup>$2</sup>");

        // TeX / Math symbols
        str = str.replace(/\\alpha\b/g, "α")
                 .replace(/\\beta\b/g, "β")
                 .replace(/\\gamma\b/g, "γ")
                 .replace(/\\delta\b/g, "δ")
                 .replace(/\\pi\b/g, "π")
                 .replace(/\\theta\b/g, "θ")
                 .replace(/\\lambda\b/g, "λ")
                 .replace(/\\sigma\b/g, "σ")
                 .replace(/\\sum\b/g, "∑")
                 .replace(/\\int\b/g, "∫")
                 .replace(/\\infty\b/g, "∞")
                 .replace(/\\approx\b/g, "≈")
                 .replace(/\\neq\b/g, "≠")
                 .replace(/\\le\b/g, "≤")
                 .replace(/\\ge\b/g, "≥")
                 .replace(/\\times\b/g, "×")
                 .replace(/\\div\b/g, "÷")
                 .replace(/\\pm\b/g, "±")
                 .replace(/\\sqrt\{([^}]+)\}/g, "√($1)");

        root.renderedMarkdown = str;
    }

    function exitEditMode() {
        if (!root.previewMode) {
            root.previewMode = true;
            focusSink.forceActiveFocus();
            Services.NotesService.flush(false);
        }
    }

    function beginEditMode(clickX, clickY) {
        if (!Services.NotesService.managementEnabled)
            return;
        root.previewMode = false;
        Qt.callLater(function() {
            notesInput.forceActiveFocus();
            if (typeof clickX === "number" && typeof clickY === "number") {
                var position = notesInput.positionAt(clickX, clickY);
                notesInput.cursorPosition = position >= 0
                    ? position
                    : notesInput.text.length;
            }
        });
    }

    function beginCreatingNote() {
        if (!Services.NotesService.managementEnabled)
            return;
        root.exitEditMode();
        root.creatingNote = true;
        newNoteInput.text = "";
        newNoteInput.forceActiveFocus();
    }

    onPreviewModeChanged: {
        if (root.previewMode)
            root.updateRenderedMarkdown();
    }

    function syncFromService() {
        if (notesInput.text === Services.NotesService.text)
            return;

        root.syncingFromService = true;
        notesInput.text = Services.NotesService.text;
        root.syncingFromService = false;
        if (root.previewMode)
            root.updateRenderedMarkdown();
    }

    onDashboardActiveChanged: {
        if (root.dashboardActive) {
            Services.NotesService.read();
        } else {
            root.exitEditMode();
        }
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

    Connections {
        target: root.Window ? root.Window.window : null
        function onActiveFocusItemChanged() {
            if (!root.previewMode && root.Window && root.Window.window && root.Window.window.activeFocusItem !== notesInput) {
                root.exitEditMode();
            }
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

    Flickable {
        id: tabsFlickable
        width: parent.width
        height: 24
        contentWidth: tabsRow.width
        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        function reveal(item) {
            var leftEdge = item.x;
            var rightEdge = item.x + item.width;
            if (leftEdge < tabsFlickable.contentX)
                tabsFlickable.contentX = leftEdge;
            else if (rightEdge > tabsFlickable.contentX + tabsFlickable.width)
                tabsFlickable.contentX = rightEdge - tabsFlickable.width;
        }

        Row {
            id: tabsRow
            spacing: ThemeModule.Theme.spacingSmall
            height: parent.height

            Repeater {
                id: tabsRepeater
                model: Services.NotesService.noteList
                delegate: Rectangle {
                    id: tabItem
                    required property string modelData
                    readonly property bool isSelected: Services.NotesService.currentNote === tabItem.modelData
                    height: 24
                    width: tabText.implicitWidth + (root.canDeleteNote ? 28 : 16)
                    radius: ThemeModule.Theme.borderRadiusSmall
                    activeFocusOnTab: tabItem.enabled
                    enabled: Services.NotesService.managementEnabled
                    opacity: tabItem.enabled ? 1.0 : 0.55
                    color: tabItem.isSelected
                        ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.25)
                        : (tabHover.hovered
                            ? Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.4)
                            : Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.15))
                    border.width: tabItem.activeFocus ? 2 : 1
                    border.color: tabItem.activeFocus || tabItem.isSelected
                        ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.6)
                        : "transparent"

                    Accessible.role: Accessible.PageTab
                    Accessible.name: tabItem.modelData
                    Accessible.description: tabItem.isSelected ? "Current note" : "Switch note"
                    Accessible.onPressAction: tabItem.activate()

                    function activate() {
                        if (!tabItem.enabled)
                            return;
                        root.exitEditMode();
                        Services.NotesService.selectNote(tabItem.modelData);
                    }

                    function focusRelative(offset) {
                        var index = Services.NotesService.noteList.indexOf(tabItem.modelData);
                        var count = Services.NotesService.noteList.length;
                        if (index < 0 || count === 0)
                            return;
                        var nextItem = tabsRepeater.itemAt((index + offset + count) % count);
                        if (nextItem)
                            nextItem.forceActiveFocus();
                    }

                    onActiveFocusChanged: {
                        if (activeFocus)
                            tabsFlickable.reveal(tabItem);
                    }

                    Keys.onPressed: function(event) {
                        if (!tabItem.enabled || event.isAutoRepeat)
                            return;
                        if (event.key === Qt.Key_Return
                                || event.key === Qt.Key_Enter
                                || event.key === Qt.Key_Space) {
                            tabItem.activate();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Left) {
                            tabItem.focusRelative(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Right) {
                            tabItem.focusRelative(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Delete && root.canDeleteNote) {
                            root.exitEditMode();
                            Services.NotesService.deleteNote(tabItem.modelData);
                            event.accepted = true;
                        }
                    }

                    HoverHandler {
                        id: tabHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            tabItem.forceActiveFocus();
                            tabItem.activate();
                        }
                    }

                    Text {
                        id: tabText
                        text: tabItem.modelData
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: ThemeModule.Theme.fontFamily
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        color: tabItem.isSelected ? ThemeModule.Theme.text : ThemeModule.Theme.subtext
                    }

                    Components.IconButton {
                        id: deleteButton
                        anchors.right: parent.right
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        size: 18
                        iconName: "trash"
                        iconSize: 11
                        iconColor: deleteButton.containsMouse
                            ? ThemeModule.Theme.error
                            : ThemeModule.Theme.subtext
                        enabled: root.canDeleteNote
                        visible: root.canDeleteNote && (tabHover.hovered
                            || tabItem.activeFocus
                            || deleteButton.activeFocus)
                        tooltipText: "Delete " + tabItem.modelData
                        onClicked: {
                            root.exitEditMode();
                            Services.NotesService.deleteNote(tabItem.modelData);
                        }
                    }
                }
            }

            Rectangle {
                id: newTabButton
                height: 24
                width: root.creatingNote ? 110 : 24
                radius: ThemeModule.Theme.borderRadiusSmall
                color: root.creatingNote
                    ? Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.5)
                    : (newTabHover.hovered
                        ? Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.4)
                        : Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.15))
                border.width: 1
                border.color: root.creatingNote
                    ? ThemeModule.Theme.accent
                    : (newTabButton.activeFocus ? ThemeModule.Theme.accent : "transparent")
                activeFocusOnTab: newTabButton.enabled && !root.creatingNote
                enabled: Services.NotesService.managementEnabled
                opacity: newTabButton.enabled ? 1.0 : 0.55

                Accessible.role: Accessible.Button
                Accessible.name: "Create note"
                Accessible.onPressAction: root.beginCreatingNote()

                onActiveFocusChanged: {
                    if (activeFocus)
                        tabsFlickable.reveal(newTabButton);
                }

                Keys.onPressed: function(event) {
                    if (!newTabButton.enabled || root.creatingNote || event.isAutoRepeat)
                        return;
                    if (event.key === Qt.Key_Return
                            || event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Space) {
                        root.beginCreatingNote();
                        event.accepted = true;
                    }
                }

                Behavior on width {
                    NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutCubic }
                }

                HoverHandler {
                    id: newTabHover
                    enabled: !root.creatingNote
                }

                MouseArea {
                    anchors.fill: parent
                    visible: !root.creatingNote
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        newTabButton.forceActiveFocus();
                        root.beginCreatingNote();
                    }
                }

                Components.AppIcon {
                    name: "plus"
                    size: 14
                    iconColor: ThemeModule.Theme.subtext
                    anchors.centerIn: parent
                    visible: !root.creatingNote
                }

                TextInput {
                    id: newNoteInput
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    verticalAlignment: TextInput.AlignVCenter
                    visible: root.creatingNote
                    color: ThemeModule.Theme.text
                    font.family: ThemeModule.Theme.fontFamily
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    clip: true
                    maximumLength: 60
                    Accessible.name: "Note name"

                    onAccepted: {
                        if (text.trim() !== "")
                            Services.NotesService.createNote(text.trim());
                        root.creatingNote = false;
                    }

                    onActiveFocusChanged: {
                        if (!activeFocus && root.creatingNote) {
                            if (text.trim() !== "")
                                Services.NotesService.createNote(text.trim());
                            root.creatingNote = false;
                        }
                    }

                    Keys.onEscapePressed: {
                        root.creatingNote = false;
                        newTabButton.forceActiveFocus();
                    }
                }
            }
        }
    }

    Rectangle {
        id: deleteUndoBar

        readonly property string pendingName: Services.NotesService.pendingDeleteNote
        property real progress: 0

        visible: pendingName !== ""
        width: parent.width
        height: visible ? 32 : 0
        radius: ThemeModule.Theme.borderRadiusSmall
        color: Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.34)
        border.width: ThemeModule.Theme.borderWidth
        border.color: Qt.rgba(ThemeModule.Theme.warning.r, ThemeModule.Theme.warning.g, ThemeModule.Theme.warning.b, 0.42)
        clip: true

        Accessible.role: Accessible.AlertMessage
        Accessible.name: pendingName !== "" ? pendingName + " deleted. Undo available." : ""

        onPendingNameChanged: {
            if (pendingName !== "") {
                progress = 1;
                deleteCountdown.restart();
            } else {
                deleteCountdown.stop();
                progress = 0;
            }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: ThemeModule.Theme.spacingSmall
            anchors.rightMargin: ThemeModule.Theme.spacingTiny
            spacing: ThemeModule.Theme.spacingSmall

            Components.AppIcon {
                name: "trash"
                size: 13
                iconColor: ThemeModule.Theme.warning
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                width: Math.max(0, deleteUndoBar.width
                    - undoDeleteButton.width
                    - ThemeModule.Theme.spacingSmall * 4
                    - 13)
                text: deleteUndoBar.pendingName + " deleted"
                elide: Text.ElideRight
                color: ThemeModule.Theme.text
                font.family: ThemeModule.Theme.fontFamily
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }

            Components.InlineActionChip {
                id: undoDeleteButton
                text: "Undo"
                iconName: "back"
                tone: "warning"
                anchors.verticalCenter: parent.verticalCenter
                enabled: !Services.NotesService.mutating
                onActivated: {
                    deleteCountdown.stop();
                    Services.NotesService.undoDelete();
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: parent.width * deleteUndoBar.progress
            height: 1
            color: ThemeModule.Theme.warning
        }

        NumberAnimation {
            id: deleteCountdown
            target: deleteUndoBar
            property: "progress"
            from: 1
            to: 0
            duration: 5000
        }
    }

    Rectangle {
        width: parent.width
        height: Math.min(root.editorMaximumHeight, Math.max(root.editorMinimumHeight, root.editorPreferredHeight))
        radius: ThemeModule.Theme.borderRadiusSmall
        color: Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.22)
        border.width: 1
        border.color: (!root.previewMode && notesInput.activeFocus)
            ? ThemeModule.Theme.accent
            : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.24)

        Flickable {
            id: notesFlickable
            anchors.fill: parent
            anchors.margins: root.editorPadding
            readonly property bool needsVerticalScroll: contentHeight > height + 1
            readonly property int scrollbarInset: root.editorScrollbarInset
            contentWidth: Math.max(0, width - (needsVerticalScroll ? scrollbarInset : 0))
            contentHeight: Math.max(
                root.previewMode ? markdownText.implicitHeight : notesInput.implicitHeight,
                height
            )
            boundsBehavior: Flickable.StopAtBounds
            interactive: needsVerticalScroll
            clip: true

            ScrollBar.vertical: ScrollBar {
                policy: notesFlickable.needsVerticalScroll ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            }

            TextArea {
                id: notesInput
                visible: !root.previewMode
                width: notesFlickable.contentWidth
                height: notesFlickable.contentHeight
                wrapMode: TextEdit.Wrap
                background: null
                topPadding: 0
                bottomPadding: 0
                leftPadding: 0
                rightPadding: 0
                placeholderText: "Keep notes, prompts, commands, or text you want nearby.\nEnter to finish · Shift+Enter for a new line"
                color: ThemeModule.Theme.text
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                enabled: Services.NotesService.managementEnabled

                onTextChanged: {
                    if (!root.syncingFromService)
                        Services.NotesService.setText(text);
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        root.exitEditMode();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (event.modifiers & Qt.ShiftModifier) {
                            var position = notesInput.cursorPosition;
                            notesInput.insert(position, "\n");
                            notesInput.cursorPosition = position + 1;
                        } else {
                            root.exitEditMode();
                        }
                        event.accepted = true;
                    }
                }

                onActiveFocusChanged: {
                    if (!activeFocus) {
                        root.exitEditMode();
                    }
                }
            }

            Item {
                visible: root.previewMode
                width: notesFlickable.contentWidth
                height: Math.max(markdownText.implicitHeight, notesFlickable.height)

                Text {
                    id: markdownText
                    width: parent.width
                    text: root.renderedMarkdown !== "" ? root.renderedMarkdown : "*No note content. Click anywhere in box to edit.*"
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                    color: ThemeModule.Theme.text
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    onLinkActivated: (link) => Qt.openUrlExternally(link)
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: markdownText.linkAt(mouseX, mouseY) !== ""
                        ? Qt.PointingHandCursor
                        : Qt.IBeamCursor
                    onClicked: (mouse) => {
                        var link = markdownText.linkAt(mouse.x, mouse.y);
                        if (link !== "") {
                            Qt.openUrlExternally(link);
                            return;
                        }
                        root.beginEditMode(mouse.x, mouse.y);
                    }
                }
            }
        }
    }
}
