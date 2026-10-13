pragma ComponentBehavior: Bound
// qmllint disable missing-type unresolved-type
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import "../theme" as ThemeModule
import "../components" as Components
import "../services" as Services
import "../widgets" as Widgets
import "WidgetRegistry.js" as WidgetRegistry

Item {
    id: dashboard

    clip: true

    property var config: null
    property bool presented: false
    
    property string selectedPanel: ""
    property string selectedBottomPanel: WidgetRegistry.defaultReservedBottomPanel
    readonly property string defaultPanel: WidgetRegistry.primaryPanel
    readonly property bool audioCombined: !dashboard.config || dashboard.config.audioPanelMode !== "separate"
    readonly property string activePanel: {
        var requested = WidgetRegistry.canonicalName(dashboard.selectedPanel);
        if (requested === "audioInputControl" && dashboard.audioCombined)
            requested = "audioControl";
        if (WidgetRegistry.isSidebarPanel(requested)
                && dashboard.isWidgetAvailable(requested))
            return requested;
        return dashboard.defaultPanel;
    }
    readonly property string activeBottomPanel: {
        if (WidgetRegistry.isReservedBottomPanel(dashboard.selectedBottomPanel)
                && dashboard.isWidgetAvailable(dashboard.selectedBottomPanel))
            return dashboard.selectedBottomPanel;

        for (var i = 0; i < WidgetRegistry.reservedBottomPanels.length; i++) {
            var panelName = WidgetRegistry.reservedBottomPanels[i];
            if (dashboard.isWidgetAvailable(panelName))
                return panelName;
        }
        return "";
    }
    // The panel's surface, with the theme effects' backdrop; its cut corners and
    // accent edge face the screen's center.
    Components.Surface {
        anchors.fill: parent
        backdrop: true
        cutTopRight: true
        cutBottomRight: true
        edge: "right"
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: ThemeModule.Theme.borderWidth
        anchors.topMargin: ThemeModule.Theme.borderWidth
        anchors.bottomMargin: ThemeModule.Theme.borderWidth
        width: ThemeModule.Theme.sidebarWidth - ThemeModule.Theme.borderWidth
        color: ThemeModule.Theme.mantle
    }

    onActivePanelChanged: {
        middleFlickable.contentY = 0;
        scrollResetTimer.restart();
    }

    Timer {
        id: scrollResetTimer
        interval: ThemeModule.Theme.animDuration + 50
        repeat: false
        onTriggered: middleFlickable.contentY = 0
    }

    function widgetSource(name) {
        return WidgetRegistry.source(name);
    }

    function isWidgetAvailable(name) {
        return !!name && dashboard.widgetSource(name) !== ""
            && Services.DashboardService.isPanelSupported(name);
    }

    function sidebarIcon(name) {
        return WidgetRegistry.icon(name);
    }

    function getStatusText(widget) {
        if (widget === "audioControl") return "Volume: " + Services.AudioService.outputVolumePercent + "%";
        if (widget === "audioInputControl") return "Mic: " + Services.AudioService.inputVolumePercent + "%";
        if (widget === "networkPanel") {
            var wifi = Services.NetworkService.connectedWifi;
            if (wifi)
                return "WiFi: " + wifi.name;
            return Services.NetworkService.wifiOn ? "Disconnected" : "WiFi Off";
        }
        if (widget === "bluetoothPanel")
            return Services.BluetoothService.enabled ? "Bluetooth On" : "Bluetooth Off";
        if (widget === "clipboardManager") {
            var clipCount = Services.ClipboardService.history.length;
            return clipCount > 0 ? "Clipboard (" + clipCount + " item" + (clipCount === 1 ? "" : "s") + ")" : "Clipboard";
        }
        if (widget === "themes")
            return "Theme: " + Services.ThemeService.theme.name;
        return WidgetRegistry.label(widget);
    }

    function isSidebarItemCurrent(widgetName) {
        if (WidgetRegistry.isReservedBottomPanel(widgetName))
            return dashboard.activeBottomPanel === widgetName;
        return dashboard.activePanel === widgetName;
    }

    function activateSidebarItem(widgetName) {
        if (WidgetRegistry.isReservedBottomPanel(widgetName)) {
            dashboard.showBottomPanel(widgetName);
            return;
        }
        if (!dashboard.isWidgetAvailable(widgetName) || dashboard.activePanel === widgetName)
            return;

        dashboard.selectedPanel = widgetName;
    }

    function showBottomPanel(widgetName) {
        var panelName = WidgetRegistry.canonicalName(widgetName);
        if (WidgetRegistry.isReservedBottomPanel(panelName)
                && dashboard.isWidgetAvailable(panelName))
            dashboard.selectedBottomPanel = panelName;
    }

    function setupLoadedWidget(item, widgetName) {
        if (!item)
            return;
        if ("presented" in item)
            item.presented = Qt.binding(function() { return dashboard.presented; });
        if ("collapsible" in item) {
            item.collapsible = false;
            item.collapsed = false;
        }
        dashboard.configureLoadedWidget(item, widgetName);
    }

    function configureLoadedWidget(item, widgetName) {
        if (!item)
            return;

        var cfg = dashboard.config || ({});
        if (widgetName === "audioControl") {
            if ("quickSwitchDevices" in item)
                item.quickSwitchDevices = cfg.audioQuickSwitch || [];
            if ("deviceDisplayNames" in item)
                item.deviceDisplayNames = cfg.audioDeviceNames || ({});
            if ("inputQuickSwitchDevices" in item)
                item.inputQuickSwitchDevices = cfg.audioInputQuickSwitch || [];
            if ("inputDeviceDisplayNames" in item)
                item.inputDeviceDisplayNames = cfg.audioInputDeviceNames || ({});
        } else if (widgetName === "audioInputControl") {
            if ("quickSwitchDevices" in item)
                item.quickSwitchDevices = cfg.audioInputQuickSwitch || [];
            if ("deviceDisplayNames" in item)
                item.deviceDisplayNames = cfg.audioInputDeviceNames || ({});
        }
    }

    onConfigChanged: {
        dashboard.configureLoadedWidget(activePanelLoader.item, dashboard.activePanel);
        dashboard.configureLoadedWidget(reservedBottomPanelLoader.item, dashboard.activeBottomPanel);
    }

    Connections {
        target: Services.DashboardService

        function onPanelRequested(panelName) {
            if (WidgetRegistry.isReservedBottomPanel(panelName))
                dashboard.showBottomPanel(panelName);
            else if (WidgetRegistry.isPrimaryPanel(panelName)
                    || WidgetRegistry.isHeaderPanel(panelName)
                    || WidgetRegistry.isPrimaryPanelWidget(panelName))
                dashboard.selectedPanel = WidgetRegistry.primaryPanel;
            else if (WidgetRegistry.isSidebarPanel(panelName)
                    && dashboard.isWidgetAvailable(panelName))
                dashboard.selectedPanel = panelName;
        }
    }

    Item {
        anchors.fill: parent

        // ── Sidebar Rail ──
        Item {
            id: sidebarRail
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: ThemeModule.Theme.sidebarWidth
            z: 20

            Column {
                id: sidebarTopCol
                anchors.top: parent.top
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Components.SpeshellMarkButton {
                    active: dashboard.activePanel === WidgetRegistry.primaryPanel
                    onActivated: dashboard.selectedPanel = WidgetRegistry.primaryPanel
                }

                Repeater {
                    model: WidgetRegistry.sidebarPanels.filter(function(widgetName) {
                        if (widgetName === "audioInputControl" && dashboard.audioCombined)
                            return false;
                        return dashboard.isWidgetAvailable(widgetName);
                    })
                    delegate: Components.SidebarIcon {
                        required property var modelData
                        property string wName: modelData
                        // The combined audio panel's icon splits into speaker and microphone halves.
                        readonly property bool audioSplit: wName === "audioControl" && dashboard.audioCombined

                        widgetName: wName
                        iconName: dashboard.sidebarIcon(wName)
                        active: dashboard.isSidebarItemCurrent(wName)
                        statusText: dashboard.getStatusText(wName)
                        secondaryIconName: audioSplit ? dashboard.sidebarIcon("audioInputControl") : ""
                        secondaryStatusText: audioSplit ? dashboard.getStatusText("audioInputControl") : ""

                        onActivated: function(name) {
                            dashboard.activateSidebarItem(name);
                        }

                        onWheelDelta: function(delta, secondary) {
                            if (wName === "audioInputControl" || (wName === "audioControl" && secondary))
                                Services.AudioService.stepInputVolume(delta);
                            else if (wName === "audioControl")
                                Services.AudioService.stepOutputVolume(delta);
                        }
                    }
                }
            }

            Column {
                id: sidebarBottomCol
                anchors.bottom: parent.bottom
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Repeater {
                    model: WidgetRegistry.reservedBottomPanels.filter(function(widgetName) {
                        return dashboard.isWidgetAvailable(widgetName);
                    })
                    delegate: Components.SidebarIcon {
                        required property var modelData
                        property string wName: modelData

                        widgetName: wName
                        iconName: dashboard.sidebarIcon(wName)
                        active: dashboard.isSidebarItemCurrent(wName)
                        statusText: dashboard.getStatusText(wName)

                        onActivated: function(name) {
                            dashboard.activateSidebarItem(name);
                        }
                    }
                }
            }

            // ── System Tray: other apps' icons, in a well of their own above the
            // bottom group, so they don't read as Speshell's panels ──
            Rectangle {
                anchors.bottom: sidebarBottomCol.top
                anchors.bottomMargin: ThemeModule.Theme.spacingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                visible: sidebarTrayRepeater.count > 0
                width: ThemeModule.Theme.controlHeight + ThemeModule.Theme.spacingTiny * 2
                height: trayColumn.implicitHeight + ThemeModule.Theme.spacingTiny * 2
                radius: ThemeModule.Theme.borderRadius
                color: ThemeModule.Theme.controlFill
                border.width: ThemeModule.Theme.borderWidth
                border.color: ThemeModule.Theme.controlBorder

                Column {
                    id: trayColumn
                    anchors.centerIn: parent
                    spacing: ThemeModule.Theme.spacingTiny

                    Repeater {
                        id: sidebarTrayRepeater
                        model: SystemTray.items
                        delegate: Item {
                            id: sidebarTrayDelegate
                            required property var modelData
                            property bool pointerInside: false
                            readonly property bool containingWindowVisible: !!(sidebarTrayDelegate.Window
                                && sidebarTrayDelegate.Window.window
                                && sidebarTrayDelegate.Window.window.visible)
                            readonly property string labelText: modelData.tooltipTitle
                                || modelData.title
                                || modelData.id
                                || "System tray icon"
                            width: ThemeModule.Theme.controlHeight
                            height: ThemeModule.Theme.controlHeight

                            Connections {
                                target: sidebarTrayDelegate.Window
                                    ? sidebarTrayDelegate.Window.window
                                    : null

                                function onVisibleChanged() {
                                    if (!sidebarTrayDelegate.containingWindowVisible)
                                        sidebarTrayDelegate.pointerInside = false;
                                }
                            }

                            Accessible.role: Accessible.Button
                            Accessible.name: sidebarTrayDelegate.labelText
                            Accessible.onPressAction: {
                                if (sidebarTrayDelegate.modelData.onlyMenu && sidebarTrayDelegate.modelData.hasMenu)
                                    sidebarTrayMenu.open();
                                else
                                    sidebarTrayDelegate.modelData.activate();
                            }

                            Rectangle {
                                id: trayIconRect
                                anchors.fill: parent
                                color: sidebarTrayDelegate.pointerInside
                                    ? ThemeModule.Theme.cardHover
                                    : "transparent"
                                radius: ThemeModule.Theme.borderRadiusSmall

                                Image {
                                    id: sidebarTrayImg
                                    anchors.centerIn: parent
                                    width: ThemeModule.Theme.iconSizeMedium
                                    height: ThemeModule.Theme.iconSizeMedium
                                    property string iconPath: {
                                        var icon = sidebarTrayDelegate.modelData.icon;
                                        if (!icon) return "";
                                        var s = icon.toString();
                                        var pi = s.indexOf("?path=");
                                        return pi !== -1 ? s.substring(0, pi) : s;
                                    }
                                    visible: iconPath !== ""
                                    source: iconPath
                                    sourceSize: Qt.size(ThemeModule.Theme.iconSizeMedium, ThemeModule.Theme.iconSizeMedium)
                                    fillMode: Image.PreserveAspectFit
                                }

                                Components.AppIcon {
                                    anchors.centerIn: parent
                                    name: "tray-fallback"
                                    size: ThemeModule.Theme.iconSizeMedium
                                    iconColor: ThemeModule.Theme.subtext
                                    visible: !sidebarTrayImg.visible
                                }

                                Components.HoverLabel {
                                    visible: sidebarTrayDelegate.containingWindowVisible
                                        && sidebarTrayDelegate.pointerInside
                                        && sidebarTrayDelegate.labelText !== ""
                                    text: sidebarTrayDelegate.labelText
                                }

                                QsMenuAnchor {
                                    id: sidebarTrayMenu
                                    menu: sidebarTrayDelegate.modelData.menu
                                    anchor.item: trayIconRect
                                    // Quickshell's type info declares Edges as an enum, not flags.
                                    // qmllint disable incompatible-type
                                    anchor.edges: Edges.Right
                                    anchor.gravity: Edges.Right
                                    // qmllint enable incompatible-type
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onEntered: sidebarTrayDelegate.pointerInside = true
                                    onExited: sidebarTrayDelegate.pointerInside = false
                                    onCanceled: sidebarTrayDelegate.pointerInside = false
                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.LeftButton) {
                                            if (sidebarTrayDelegate.modelData.onlyMenu && sidebarTrayDelegate.modelData.hasMenu) {
                                                sidebarTrayMenu.open();
                                            } else {
                                                sidebarTrayDelegate.modelData.activate();
                                            }
                                        } else if (mouse.button === Qt.RightButton) {
                                            if (sidebarTrayDelegate.modelData.hasMenu) {
                                                sidebarTrayMenu.open();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Separator ──
        Rectangle {
            id: mainSeparator
            anchors.left: sidebarRail.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: ThemeModule.Theme.separatorThickness
            color: ThemeModule.Theme.separator
        }

        // ── Content Area ──
        Item {
            anchors.left: mainSeparator.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: ThemeModule.Theme.panelPadding

            // App-owned header.
            Column {
                id: topBlock
                anchors.top: parent.top
                width: parent.width
                spacing: 0

                Widgets.Clock {
                    width: parent.width
                    presented: dashboard.presented
                }

                Item { width: 1; height: ThemeModule.Theme.spacingXL }
            }

            // App-owned utility area: one exclusive panel above the bottom edge.
            Column {
                id: bottomBlock
                anchors.bottom: parent.bottom
                width: parent.width
                spacing: 0

                Item { width: 1; height: ThemeModule.Theme.spacingXL }

                Item {
                    width: parent.width
                    height: reservedAreaDivider.height
                        + ThemeModule.Theme.spacingLarge
                        + Math.max(ThemeModule.Theme.reservedBottomPanelHeight,
                            reservedBottomPanelLoader.height)

                    Rectangle {
                        id: reservedAreaDivider

                        anchors.top: parent.top
                        width: parent.width
                        height: ThemeModule.Theme.separatorThickness
                        color: ThemeModule.Theme.separator
                    }

                    Loader {
                        id: reservedBottomPanelLoader

                        anchors.top: reservedAreaDivider.bottom
                        anchors.topMargin: ThemeModule.Theme.spacingLarge
                        width: parent.width
                        active: dashboard.activeBottomPanel !== ""
                        source: active ? dashboard.widgetSource(dashboard.activeBottomPanel) : ""

                        onLoaded: dashboard.setupLoadedWidget(item, dashboard.activeBottomPanel)
                    }
                }
            }

            // ── Scrollable Middle Zone ── (anchored between topBlock and bottomBlock)
            Flickable {
                id: middleFlickable
                anchors.top: topBlock.bottom
                anchors.bottom: bottomBlock.top
                width: parent.width
                contentHeight: middleContentColumn.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 3000
                readonly property bool needsVerticalScroll: contentHeight > height + 1
                readonly property int scrollbarInset: ThemeModule.Theme.panelPadding

                ScrollBar.vertical: ScrollBar {
                    policy: middleFlickable.needsVerticalScroll ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: ThemeModule.Theme.overlay
                        opacity: 0.5
                    }
                }

                Item {
                    id: middleContentColumn
                    width: middleFlickable.width - middleFlickable.scrollbarInset
                    height: activePanelLoader.height

                    x: dashboard.activePanel !== "" ? 0 : -20
                    opacity: dashboard.activePanel !== "" ? 1.0 : 0.0
                    visible: opacity > 0

                    Behavior on x { NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing } }
                    Behavior on opacity { NumberAnimation { duration: ThemeModule.Theme.animDuration } }

                    Loader {
                        id: activePanelLoader
                        width: parent.width
                        active: dashboard.isWidgetAvailable(dashboard.activePanel)
                        source: active ? dashboard.widgetSource(dashboard.activePanel) : ""

                        onLoaded: dashboard.setupLoadedWidget(item, dashboard.activePanel)
                    }
                }
            }
        }
    }

    // The theme effects' interactions: small effects over the panel where the user
    // drags a slider, flips a switch, or picks something. They take no input.
    Loader {
        id: interactionsLoader

        // EffectClock runs at this speed and frame rate.
        property real timeScale: Services.EffectsService.dashboardSpeed
        property int frameRate: Services.EffectsService.frameRate

        z: 200
        anchors.fill: parent
        enabled: false
        active: dashboard.presented && Services.EffectsService.dashboardInteractions !== null
        sourceComponent: Services.EffectsService.dashboardInteractions
    }

    // Untyped, so the effects' functions can be called on it.
    readonly property var interactions: interactionsLoader.item

    Binding {
        target: interactionsLoader.item
        property: "theme"
        value: ThemeModule.Theme
    }

    // Whether `item` is part of this dashboard; popups and other windows are not.
    function holds(item) {
        for (var parentItem = item; parentItem; parentItem = parentItem.parent) {
            if (parentItem === dashboard)
                return true;
        }
        return false;
    }

    function areaOf(item) {
        return item.mapToItem(interactionsLoader, 0, 0, item.width, item.height);
    }

    Connections {
        target: Services.EffectsService
        enabled: interactionsLoader.status === Loader.Ready

        function onKnobMoved(knob, dx) {
            if (dashboard.holds(knob))
                dashboard.interactions.slide(knob.mapToItem(interactionsLoader, knob.width / 2, knob.height / 2), dx);
        }

        function onKnobReleased(knob) {
            if (dashboard.holds(knob))
                dashboard.interactions.release(knob.mapToItem(interactionsLoader, knob.width / 2, knob.height / 2));
        }

        function onPicked(target) {
            if (dashboard.holds(target))
                dashboard.interactions.pick(dashboard.areaOf(target));
        }

        function onSwitched(control, on) {
            if (dashboard.holds(control))
                dashboard.interactions.toggle(dashboard.areaOf(control), on);
        }
    }
}
