pragma ComponentBehavior: Bound
// qmllint disable uncreatable-type
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

PanelWindow {
    id: root

    property var config: null
    property bool opened: false
    property bool focusGrabActive: false
    property var targetScreen: null
    property int selectedIndex: 0
    readonly property bool mapped: root.visible && root.backingWindowVisible
    readonly property var results: Services.LauncherService.results || []
    readonly property int resultCount: root.results.length
    readonly property var launcherConfig: root.config && root.config.launcher ? root.config.launcher : ({})
    readonly property int configuredWidth: root.launcherConfig.width || 540
    readonly property int configuredVisibleRows: root.launcherConfig.visibleRows || 5
    readonly property int paletteWidth: Math.min(root.configuredWidth, Math.max(320, root.width - ThemeModule.Theme.spacingXL * 2))
    readonly property int resultRowHeight: 56
    readonly property int resultSpacing: ThemeModule.Theme.spacingTiny
    readonly property int resultViewportHeight: root.configuredVisibleRows * root.resultRowHeight
        + Math.max(0, root.configuredVisibleRows - 1) * root.resultSpacing

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

    function clampSelected() {
        root.selectedIndex = root.resultCount <= 0
            ? 0
            : Math.max(0, Math.min(root.selectedIndex, root.resultCount - 1));
    }

    function moveSelection(delta) {
        if (root.resultCount <= 0)
            return;
        root.selectedIndex = (root.selectedIndex + delta + root.resultCount) % root.resultCount;
        resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
    }

    function openLauncher() {
        root.targetScreen = root.focusedScreen();
        Services.LauncherService.clearQuery();
        root.selectedIndex = 0;
        root.opened = true;
        resultsList.contentY = 0;
    }

    function closeLauncher() {
        root.opened = false;
        Services.LauncherService.clearQuery();
        root.selectedIndex = 0;
    }

    function toggleLauncher() {
        if (root.opened) root.closeLauncher();
        else root.openLauncher();
    }

    function activateSelected() {
        if (root.resultCount <= 0)
            return;
        if (Services.LauncherService.activate(root.results[root.selectedIndex]))
            root.closeLauncher();
    }

    function completeSelected() {
        if (root.resultCount <= 0)
            return;
        var completion = Services.LauncherService.completionFor(root.results[root.selectedIndex]);
        if (completion !== "") {
            searchField.text = completion;
            searchField.cursorPosition = searchField.text.length;
        }
    }

    function iconPath(result) {
        if (!result || !result.iconSource)
            return "";
        return Quickshell.iconPath(result.iconSource, true);
    }

    visible: root.opened && root.targetScreen !== null
    screen: root.targetScreen
    color: "transparent"
    focusable: true
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    updatesEnabled: root.visible

    WlrLayershell.namespace: "speshell-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors { left: true; right: true; top: true; bottom: true }

    HyprlandFocusGrab {
        active: root.focusGrabActive
        windows: [root]
    }

    onResultCountChanged: root.clampSelected()
    onVisibleChanged: {
        if (root.visible) {
            resultsList.contentY = 0;
            focusTimer.restart();
        } else {
            focusTimer.stop();
            root.focusGrabActive = false;
        }
    }
    onBackingWindowVisibleChanged: if (root.mapped) focusTimer.restart()

    Timer {
        id: focusTimer
        interval: 60
        repeat: false
        onTriggered: {
            if (!root.mapped)
                return;
            searchField.forceActiveFocus();
            searchField.cursorPosition = searchField.text.length;
            root.focusGrabActive = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(ThemeModule.Theme.crust.r, ThemeModule.Theme.crust.g, ThemeModule.Theme.crust.b, 0.30)

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeLauncher()
        }
    }

    Rectangle {
        id: palette
        z: 1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -Math.round(parent.height * 0.10)
        width: root.paletteWidth
        height: paletteColumn.implicitHeight + ThemeModule.Theme.spacingLarge * 2
        radius: ThemeModule.Theme.borderRadiusSmall
        color: ThemeModule.Theme.bg
        border.width: ThemeModule.Theme.borderWidth
        border.color: ThemeModule.Theme.cardHover
        clip: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: function(mouse) { mouse.accepted = true; }
        }

        Column {
            id: paletteColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: ThemeModule.Theme.spacingLarge
            spacing: ThemeModule.Theme.spacingMedium

            Rectangle {
                width: parent.width
                height: 48
                radius: ThemeModule.Theme.borderRadiusSmall
                color: ThemeModule.Theme.card
                border.width: ThemeModule.Theme.borderWidth
                border.color: searchField.activeFocus ? ThemeModule.Theme.accent : ThemeModule.Theme.cardHover

                Components.AppIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: ThemeModule.Theme.spacingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    name: "search"
                    size: 19
                    iconColor: searchField.activeFocus ? ThemeModule.Theme.accent : ThemeModule.Theme.subtext
                }

                TextInput {
                    id: searchField
                    anchors.left: parent.left
                    anchors.leftMargin: 44
                    anchors.right: parent.right
                    anchors.rightMargin: ThemeModule.Theme.spacingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    text: Services.LauncherService.query
                    selectByMouse: true
                    color: ThemeModule.Theme.text
                    font.family: ThemeModule.Theme.fontFamily
                    font.pixelSize: ThemeModule.Theme.fontSizeLarge
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true

                    onTextChanged: {
                        Services.LauncherService.setQuery(text);
                        root.selectedIndex = 0;
                        resultsList.contentY = 0;
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Escape) {
                            root.closeLauncher();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            root.moveSelection(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.moveSelection(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab) {
                            root.completeSelected();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.activateSelected();
                            event.accepted = true;
                        }
                    }
                }

                Text {
                    anchors.left: searchField.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search apps, calculate, type !, or search with ?"
                    color: ThemeModule.Theme.subtext
                    font.family: ThemeModule.Theme.fontFamily
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    visible: searchField.text === "" && !searchField.preeditText
                }
            }

            ListView {
                id: resultsList
                readonly property bool scrollable: contentHeight > height + 1
                readonly property int scrollGutter: scrollable ? ThemeModule.Theme.spacingMedium : 0
                width: parent.width
                height: Math.min(contentHeight, root.resultViewportHeight)
                clip: true
                visible: root.resultCount > 0
                model: root.results
                spacing: root.resultSpacing
                currentIndex: root.selectedIndex
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 3000

                ScrollBar.vertical: ScrollBar {
                    policy: resultsList.scrollable ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: ThemeModule.Theme.overlay
                        opacity: 0.5
                    }
                }

                delegate: Rectangle {
                    id: resultRow
                    required property int index
                    required property var modelData
                    readonly property string nativeIconPath: root.iconPath(resultRow.modelData)

                    width: resultsList.width - resultsList.scrollGutter
                    height: root.resultRowHeight
                    radius: ThemeModule.Theme.borderRadiusSmall
                    opacity: modelData.activatable === false ? 0.72 : 1.0
                    color: resultRow.index === root.selectedIndex
                        ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.16)
                        : (resultMouse.containsMouse ? ThemeModule.Theme.card : "transparent")
                    border.width: resultRow.index === root.selectedIndex ? ThemeModule.Theme.borderWidth : 0
                    border.color: Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.42)

                    Item {
                        id: resultIcon
                        anchors.left: parent.left
                        anchors.leftMargin: ThemeModule.Theme.spacingMedium
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 30

                        IconImage {
                            anchors.centerIn: parent
                            width: 27
                            height: 27
                            source: resultRow.nativeIconPath
                            asynchronous: true
                            visible: resultRow.nativeIconPath !== ""
                        }

                        Components.AppIcon {
                            anchors.centerIn: parent
                            name: resultRow.modelData.iconName || "apps"
                            size: 22
                            iconColor: resultRow.modelData.kind === "error"
                                ? ThemeModule.Theme.error
                                : ThemeModule.Theme.subtext
                            visible: resultRow.nativeIconPath === ""
                        }
                    }

                    Column {
                        anchors.left: resultIcon.right
                        anchors.leftMargin: ThemeModule.Theme.spacingMedium
                        anchors.right: resultKind.left
                        anchors.rightMargin: ThemeModule.Theme.spacingMedium
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: resultRow.modelData.title || ""
                            color: ThemeModule.Theme.text
                            font.family: ThemeModule.Theme.fontFamily
                            font.pixelSize: ThemeModule.Theme.fontSizeNormal
                            font.bold: resultRow.modelData.kind === "calculator"
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: resultRow.modelData.subtitle || ""
                            color: resultRow.modelData.kind === "error"
                                ? ThemeModule.Theme.error
                                : ThemeModule.Theme.subtext
                            font.family: ThemeModule.Theme.fontFamily
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            elide: Text.ElideRight
                            visible: text !== ""
                        }
                    }

                    Text {
                        id: resultKind
                        anchors.right: parent.right
                        anchors.rightMargin: ThemeModule.Theme.spacingMedium
                        anchors.verticalCenter: parent.verticalCenter
                        text: resultRow.modelData.badge || ""
                        color: resultRow.index === root.selectedIndex ? ThemeModule.Theme.accent : ThemeModule.Theme.overlay
                        font.family: ThemeModule.Theme.fontFamily
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.8
                    }

                    MouseArea {
                        id: resultMouse
                        anchors.fill: parent
                        enabled: resultRow.modelData.activatable !== false
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onEntered: root.selectedIndex = resultRow.index
                        onClicked: {
                            root.selectedIndex = resultRow.index;
                            root.activateSelected();
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 54
                visible: root.resultCount === 0

                Row {
                    anchors.centerIn: parent
                    spacing: ThemeModule.Theme.spacingSmall

                    Components.AppIcon {
                        name: "search"
                        size: 17
                        iconColor: ThemeModule.Theme.overlay
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: Services.LauncherService.emptyMessage()
                        color: ThemeModule.Theme.subtext
                        font.family: ThemeModule.Theme.fontFamily
                        font.pixelSize: ThemeModule.Theme.fontSizeNormal
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Text {
                width: parent.width
                text: Services.LauncherService.activationError
                color: ThemeModule.Theme.error
                font.family: ThemeModule.Theme.fontFamily
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                visible: text !== ""
            }
        }
    }
}
