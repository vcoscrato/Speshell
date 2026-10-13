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
import "../services/ThemeProvider.js" as ThemeProvider
import "../theme" as ThemeModule

PanelWindow {
    id: root

    property var config: null
    property bool opened: false
    // Mapped on screen; outlives `opened` while an effects transition plays the exit.
    property bool presenting: false
    property bool focusGrabActive: false
    property var targetScreen: null
    property int selectedIndex: 0
    readonly property bool mapped: root.visible && root.backingWindowVisible
    // Latched per presentation so an effects change, e.g. from picking a theme, lets
    // the old effects finish their exit.
    property Component transition: null
    readonly property bool transitionReady: transitionLoader.status === Loader.Ready
    readonly property var results: Services.LauncherService.results || []
    readonly property int resultCount: root.results.length
    readonly property var launcherConfig: root.config && root.config.launcher ? root.config.launcher : ({})
    readonly property int configuredWidth: root.launcherConfig.width || 540
    readonly property int configuredVisibleRows: root.launcherConfig.visibleRows || 5
    readonly property int paletteWidth: Math.min(root.configuredWidth, Math.max(320, root.width - ThemeModule.Theme.spacingXL * 2))
    readonly property int resultRowHeight: Math.max(56,
        Math.ceil((ThemeModule.Theme.fontSizeNormal + ThemeModule.Theme.fontSizeSmall) * 1.25)
            + ThemeModule.Theme.spacingMedium * 2)
    readonly property int resultSpacing: ThemeModule.Theme.spacingTiny
    readonly property int resultViewportHeight: root.configuredVisibleRows * root.resultRowHeight
        + Math.max(0, root.configuredVisibleRows - 1) * root.resultSpacing

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
        root.targetScreen = Services.DashboardService.focusedScreen();
        Services.LauncherService.clearQuery();
        root.selectedIndex = 0;
        closeSafetyTimer.stop();
        if (!root.presenting)
            root.transition = Services.EffectsService.launcherTransition;
        root.opened = true;
        root.presenting = true;
        resultsList.contentY = 0;
    }

    function closeLauncher() {
        root.opened = false;
        root.focusGrabActive = false;
        if (root.transitionReady)
            closeSafetyTimer.restart();
        else
            root.finishPresentation();
    }

    // Unmap once the exit is over; the query clears only now so the exit shows the last frame.
    function finishPresentation() {
        if (root.opened)
            return;
        closeSafetyTimer.stop();
        root.presenting = false;
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

    function iconPath(result) {
        if (!result || !result.iconSource)
            return "";
        return Quickshell.iconPath(result.iconSource, true);
    }

    visible: root.presenting && root.targetScreen !== null
    screen: root.targetScreen
    color: "transparent"
    focusable: true
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    updatesEnabled: root.visible

    WlrLayershell.namespace: "speshell-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible && root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // Click-through while the exit transition plays.
    mask: root.opened ? null : passThrough

    anchors { left: true; right: true; top: true; bottom: true }

    Region { id: passThrough }

    HyprlandFocusGrab {
        active: root.focusGrabActive
        windows: [root]
    }

    // An effects transition must emit closingFinished(); this bounds a broken one.
    Timer {
        id: closeSafetyTimer
        interval: Math.round(2500 / Math.max(0.25, transitionLoader.timeScale))
        onTriggered: root.finishPresentation()
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
            if (!root.mapped || !root.opened)
                return;
            searchField.forceActiveFocus();
            searchField.cursorPosition = searchField.text.length;
            root.focusGrabActive = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ThemeModule.Theme.alpha(ThemeModule.Theme.crust, 0.30)
        opacity: root.opened ? 1 : 0

        Behavior on opacity {
            enabled: root.transitionReady
            NumberAnimation { duration: ThemeModule.Theme.animDurationSlow; easing.type: ThemeModule.Theme.animEasing }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeLauncher()
        }
    }

    Item {
        id: launcherPanel
        z: 1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -Math.round(parent.height * 0.10)
        width: root.paletteWidth
        height: paletteColumn.implicitHeight + ThemeModule.Theme.spacingLarge * 2
        clip: true

        // The dashboard's surface, and the top of its backdrop painted at about the
        // dashboard's height; centered, so cut on a diagonal.
        Components.Surface {
            anchors.fill: parent
            backdrop: true
            backdropHeight: 1050
            cutTopRight: true
            cutBottomLeft: true
        }

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
                height: Math.max(48,
                    Math.ceil(ThemeModule.Theme.fontSizeLarge * 1.35)
                        + ThemeModule.Theme.spacingMedium * 2)
                radius: ThemeModule.Theme.borderRadiusSmall
                color: ThemeModule.Theme.card
                border.width: ThemeModule.Theme.borderWidth
                border.color: searchField.activeFocus ? ThemeModule.Theme.accent : ThemeModule.Theme.cardHover

                Components.AppIcon {
                    anchors.left: parent.left
                    anchors.leftMargin: ThemeModule.Theme.spacingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    name: "search"
                    size: ThemeModule.Theme.iconSizeMedium
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
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.activateSelected();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                            if (root.resultCount > 0)
                                Services.LauncherService.complete(root.results[root.selectedIndex]);
                            event.accepted = true;
                        }
                    }
                }

                Text {
                    anchors.left: searchField.left
                    anchors.right: searchField.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search apps, calculate, ! for commands, ? for the web"
                    elide: Text.ElideRight
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
                        ? ThemeModule.Theme.selectedFill
                        : (resultMouse.containsMouse ? ThemeModule.Theme.card : "transparent")
                    border.width: resultRow.index === root.selectedIndex ? ThemeModule.Theme.borderWidth : 0
                    border.color: ThemeModule.Theme.selectedBorder

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

                        Image {
                            id: resultThumbnail
                            anchors.fill: parent
                            source: ThemeProvider.fileUrl(resultRow.modelData.thumbnail || "")
                            sourceSize: Qt.size(64, 64)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                        }

                        Components.AppIcon {
                            anchors.centerIn: parent
                            name: resultRow.modelData.iconName || "apps"
                            size: ThemeModule.Theme.iconSizeLarge
                            iconColor: resultRow.modelData.kind === "error"
                                ? ThemeModule.Theme.error
                                : ThemeModule.Theme.subtext
                            visible: resultRow.nativeIconPath === "" && !resultThumbnail.visible
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
                        font.pixelSize: ThemeModule.Theme.fontSizeMicro
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
                height: Math.max(54,
                    Math.ceil(ThemeModule.Theme.fontSizeNormal * 1.35)
                        + ThemeModule.Theme.spacingLarge * 2)
                visible: root.resultCount === 0

                Row {
                    anchors.centerIn: parent
                    spacing: ThemeModule.Theme.spacingSmall

                    Components.AppIcon {
                        name: "search"
                        size: ThemeModule.Theme.iconSizeMedium
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

    // Effects transition (see extras/effects/README.md): draws above the panel, and may capture it with
    // a ShaderEffectSource to animate the panel itself. Alive only while the launcher is mapped.
    Loader {
        id: transitionLoader
        // EffectClock runs at this speed and frame rate; a transition left running
        // after transitions are turned off finishes at normal speed.
        property real timeScale: Services.EffectsService.launcherSpeed > 0 ? Services.EffectsService.launcherSpeed : 1
        property int frameRate: Services.EffectsService.frameRate
        z: 2
        anchors.fill: parent
        active: root.transition !== null && root.presenting
        sourceComponent: root.transition
    }

    Binding {
        target: transitionLoader.item
        property: "panel"
        value: launcherPanel
    }

    Binding {
        target: transitionLoader.item
        property: "panelRect"
        value: Qt.rect(launcherPanel.x, launcherPanel.y, launcherPanel.width, launcherPanel.height)
    }

    Binding {
        target: transitionLoader.item
        property: "active"
        value: root.opened
    }

    Connections {
        target: transitionLoader.item
        ignoreUnknownSignals: true

        function onClosingFinished() { root.finishPresentation(); }
    }
}
