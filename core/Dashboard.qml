pragma ComponentBehavior: Bound
// qmllint disable missing-type unresolved-type
import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Networking
import Quickshell.Bluetooth
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
    readonly property string activePanel: {
        var requested = WidgetRegistry.canonicalName(dashboard.selectedPanel);
        if (requested === "audioInputControl"
                && dashboard.config
                && dashboard.config.audioPanelMode === "combined")
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
    Shape {
        anchors.fill: parent
        antialiasing: true

        ShapePath {
            strokeWidth: 2
            strokeColor: Qt.rgba(
                ThemeModule.Theme.surface2.r * 0.88 + ThemeModule.Theme.overlay.r * 0.12,
                ThemeModule.Theme.surface2.g * 0.88 + ThemeModule.Theme.overlay.g * 0.12,
                ThemeModule.Theme.surface2.b * 0.88 + ThemeModule.Theme.overlay.b * 0.12,
                1
            )
            fillColor: ThemeModule.Theme.bg
            capStyle: ShapePath.SquareCap
            joinStyle: ShapePath.MiterJoin
            startX: 0
            startY: 0

            PathLine { x: dashboard.width - ThemeModule.Theme.surfaceCornerCut; y: 0 }
            PathLine { x: dashboard.width; y: ThemeModule.Theme.surfaceCornerCut }
            PathLine { x: dashboard.width; y: dashboard.height - ThemeModule.Theme.surfaceCornerCut }
            PathLine { x: dashboard.width - ThemeModule.Theme.surfaceCornerCut; y: dashboard.height }
            PathLine { x: 0; y: dashboard.height }
            PathLine { x: 0; y: 0 }
        }
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

    Rectangle {
        z: 100
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 40
        anchors.bottomMargin: 40
        width: 2

        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0)
            }
            GradientStop { position: 0.10; color: ThemeModule.Theme.accent }
            GradientStop { position: 0.88; color: ThemeModule.Theme.accent }
            GradientStop {
                position: 1
                color: Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0)
            }
        }
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

    function isWidgetSupported(name) {
        if (name === "batteryStatus") return Services.FeatureSupport.supportsBattery;
        if (name === "bluetoothPanel") return Services.FeatureSupport.supportsBluetooth;
        if (name === "displayControl") return Services.FeatureSupport.supportsDisplayControl;
        return true;
    }

    function isWidgetAvailable(name) {
        return !!name && dashboard.widgetSource(name) !== "" && dashboard.isWidgetSupported(name);
    }

    function sidebarIcon(name) {
        return WidgetRegistry.icon(name);
    }

    function getMicroStatus(widget) {
        if (widget === "audioControl") return Services.AudioService.outputVolumePercent + "%";
        if (widget === "audioInputControl") return Services.AudioService.inputVolumePercent + "%";
        if (widget === "networkPanel") return "";
        if (widget === "bluetoothPanel") {
            var adapter = Bluetooth.defaultAdapter;
            if (!adapter) return "";
            var n = 0;
            for (var i = 0; i < adapter.devices.values.length; i++) {
                if (adapter.devices.values[i].connected) n++;
            }
            return n > 0 ? n.toString() : "";
        }
        return "";
    }

    function getStatusText(widget) {
        if (widget === "audioControl") return "Volume: " + Services.AudioService.outputVolumePercent + "%";
        if (widget === "audioInputControl") return "Mic: " + Services.AudioService.inputVolumePercent + "%";
        if (widget === "networkPanel") {
            for (var i = 0; i < Networking.devices.values.length; i++) {
                var dev = Networking.devices.values[i];
                if (dev.type === DeviceType.Wifi) {
                    for (var j = 0; j < dev.networks.values.length; j++) {
                        var net = dev.networks.values[j];
                        if (net.connected) return "WiFi: " + net.name;
                    }
                }
            }
            return Networking.wifiEnabled ? "Disconnected" : "WiFi Off";
        }
        if (widget === "bluetoothPanel") {
            var btAdapter = Bluetooth.defaultAdapter;
            return (btAdapter && btAdapter.enabled) ? "Bluetooth On" : "Bluetooth Off";
        }
        if (widget === "clipboardManager") {
            var clipCount = Services.ClipboardService.history.length;
            return clipCount > 0 ? "Clipboard (" + clipCount + " item" + (clipCount === 1 ? "" : "s") + ")" : "Clipboard";
        }
        return WidgetRegistry.label(widget);
    }

    function isSidebarItemCurrent(widgetName) {
        if (WidgetRegistry.isReservedBottomPanel(widgetName))
            return dashboard.activeBottomPanel === widgetName;
        return dashboard.activePanel === widgetName;
    }

    function activateSidebarItem(widgetName) {
        if (WidgetRegistry.isReservedBottomPanel(widgetName)) {
            dashboard.toggleBottomPanel(widgetName);
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

    function toggleBottomPanel(widgetName) {
        var panelName = WidgetRegistry.canonicalName(widgetName);
        if (!WidgetRegistry.isReservedBottomPanel(panelName)
                || !dashboard.isWidgetAvailable(panelName))
            return;

        dashboard.selectedBottomPanel = dashboard.activeBottomPanel === panelName
            ? WidgetRegistry.defaultReservedBottomPanel
            : panelName;
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

        if ((widgetName === "notificationCenter" || WidgetRegistry.isPrimaryPanel(widgetName))
                && "maxVisibleNotifications" in item) {
            item.maxVisibleNotifications = cfg.maxVisibleNotification !== undefined
                ? cfg.maxVisibleNotification
                : 3;
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
                        if (widgetName === "audioInputControl") {
                            var mode = Services.ConfigService.config ? Services.ConfigService.config.audioPanelMode : "combined";
                            if (mode === "combined")
                                return false;
                        }
                        return dashboard.isWidgetAvailable(widgetName);
                    })
                    delegate: Components.SidebarIcon {
                        required property var modelData
                        property string wName: modelData

                        widgetName: wName
                        iconName: dashboard.sidebarIcon(wName)
                        active: dashboard.isSidebarItemCurrent(wName)
                        microStatus: dashboard.getMicroStatus(wName)
                        statusText: dashboard.getStatusText(wName)

                        onActivated: function(name) {
                            dashboard.activateSidebarItem(name);
                        }

                        onWheelDelta: function(delta) {
                            var step = (Services.ConfigService.config && Services.ConfigService.config.audioScrollStep)
                                ? Services.ConfigService.config.audioScrollStep
                                : 5;
                            if (wName === "audioControl") {
                                var newVol = Services.AudioService.outputVolumePercent + (delta > 0 ? step : -step);
                                Services.AudioService.setOutputVolumePercent(Math.max(0, Math.min(100, newVol)));
                            } else if (wName === "audioInputControl") {
                                var newVolIn = Services.AudioService.inputVolumePercent + (delta > 0 ? step : -step);
                                Services.AudioService.setInputVolumePercent(Math.max(0, Math.min(100, newVolIn)));
                            }
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
                        microStatus: dashboard.getMicroStatus(wName)
                        statusText: dashboard.getStatusText(wName)

                        onActivated: function(name) {
                            dashboard.activateSidebarItem(name);
                        }
                    }
                }
            }

            // ── System Tray (centered in the free zone between top and bottom icons) ──
            Item {
                id: sidebarTrayZone
                anchors.top: sidebarTopCol.bottom
                anchors.bottom: sidebarBottomCol.top
                anchors.left: parent.left
                anchors.right: parent.right
                visible: sidebarTrayRepeater.count > 0

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: ThemeModule.Theme.spacingTiny

                    Repeater {
                        id: sidebarTrayRepeater
                        model: SystemTray.items
                        delegate: Item {
                            id: sidebarTrayDelegate
                            required property var modelData
                            width: ThemeModule.Theme.sidebarIconSize
                            height: ThemeModule.Theme.sidebarIconSize

                            Rectangle {
                                id: trayIconRect
                                anchors.fill: parent
                                color: sidebarTrayMouse.containsMouse ? ThemeModule.Theme.cardHover : "transparent"

                                Image {
                                    id: sidebarTrayImg
                                    anchors.centerIn: parent
                                    width: 18
                                    height: 18
                                    property string iconPath: {
                                        var icon = sidebarTrayDelegate.modelData.icon;
                                        if (!icon) return "";
                                        var s = icon.toString();
                                        var pi = s.indexOf("?path=");
                                        return pi !== -1 ? s.substring(0, pi) : s;
                                    }
                                    visible: iconPath !== ""
                                    source: iconPath
                                    sourceSize: Qt.size(18, 18)
                                    fillMode: Image.PreserveAspectFit
                                }

                                Components.AppIcon {
                                    anchors.centerIn: parent
                                    name: "tray-fallback"
                                    size: 16
                                    iconColor: ThemeModule.Theme.subtext
                                    visible: !sidebarTrayImg.visible
                                }

                                ToolTip {
                                    visible: sidebarTrayMouse.containsMouse
                                    text: sidebarTrayDelegate.modelData.tooltipTitle || sidebarTrayDelegate.modelData.title || sidebarTrayDelegate.modelData.id || "System tray icon"
                                    delay: 150
                                }

                                QsMenuAnchor {
                                    id: sidebarTrayMenu
                                    menu: sidebarTrayDelegate.modelData.menu
                                    anchor.item: trayIconRect
                                    anchor.edges: Edges.Right
                                    anchor.gravity: Edges.Right
                                }

                                MouseArea {
                                    id: sidebarTrayMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
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
            id: contentArea
            anchors.left: mainSeparator.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: ThemeModule.Theme.spacingMedium
            anchors.rightMargin: ThemeModule.Theme.spacingMedium
            anchors.leftMargin: ThemeModule.Theme.spacingMedium
            anchors.bottomMargin: ThemeModule.Theme.spacingMedium

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

                        onLoaded: {
                            if (!item)
                                return;
                            if ("presented" in item)
                                item.presented = Qt.binding(function() { return dashboard.presented; });
                            if ("collapsible" in item) {
                                item.collapsible = false;
                                item.collapsed = false;
                            }
                            dashboard.configureLoadedWidget(item, dashboard.activeBottomPanel);
                        }
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
                readonly property int scrollbarInset: ThemeModule.Theme.spacingMedium

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

                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Loader {
                        id: activePanelLoader
                        width: parent.width
                        active: dashboard.isWidgetAvailable(dashboard.activePanel)
                        source: active ? dashboard.widgetSource(dashboard.activePanel) : ""

                        onLoaded: {
                            if (!item) return;

                            if ("presented" in item) {
                                item.presented = Qt.binding(function() { return dashboard.presented; });
                            }
                            if ("collapsible" in item) {
                                item.collapsible = false;
                                item.collapsed = false;
                            }
                            dashboard.configureLoadedWidget(item, dashboard.activePanel);
                        }
                    }
                }
            }
        }
    }
}
