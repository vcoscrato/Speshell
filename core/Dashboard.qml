pragma ComponentBehavior: Bound
// qmllint disable missing-type unresolved-type
import QtQuick
import QtQuick.Templates as T
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
    // The utility area is at least this tall, whichever of its panels shows.
    readonly property int bottomPanelMinHeight: 256
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

    function isWidgetAvailable(name) {
        return !!name && WidgetRegistry.source(name) !== ""
            && Services.DashboardService.isPanelSupported(name);
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
                        iconName: WidgetRegistry.icon(wName)
                        active: dashboard.isSidebarItemCurrent(wName)
                        statusText: Services.DashboardService.statusText(wName)
                        secondaryIconName: audioSplit ? WidgetRegistry.icon("audioInputControl") : ""
                        secondaryStatusText: audioSplit ? Services.DashboardService.statusText("audioInputControl") : ""

                        onActivated: function(name) {
                            dashboard.activateSidebarItem(name);
                        }

                        onWheelDelta: function(delta, secondary) {
                            if (wName === "audioInputControl" || (wName === "audioControl" && secondary))
                                Services.AudioService.stepInputVolume(delta);
                            else if (wName === "audioControl")
                                Services.AudioService.stepOutputVolume(delta);
                        }

                        onRightClicked: function(secondary) {
                            if (wName === "audioInputControl" || (wName === "audioControl" && secondary))
                                Services.AudioService.cycleInputDevice();
                            else if (wName === "audioControl")
                                Services.AudioService.cycleOutputDevice();
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
                        iconName: WidgetRegistry.icon(wName)
                        active: dashboard.isSidebarItemCurrent(wName)
                        statusText: Services.DashboardService.statusText(wName)

                        onActivated: function(name) {
                            dashboard.activateSidebarItem(name);
                        }
                    }
                }
            }

            // ── System Tray: other apps' icons, in a well of their own centered in
            // the gap between the panel groups, so they don't read as Speshell's panels ──
            Item {
                anchors.top: sidebarTopCol.bottom
                anchors.bottom: sidebarBottomCol.top
                anchors.topMargin: ThemeModule.Theme.spacingLarge
                anchors.bottomMargin: ThemeModule.Theme.spacingLarge
                width: parent.width

                Rectangle {
                    anchors.centerIn: parent
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
                            delegate: Components.TrayItem {}
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
                        + Math.max(dashboard.bottomPanelMinHeight,
                            reservedBottomPanelLoader.height)

                    Rectangle {
                        id: reservedAreaDivider

                        anchors.top: parent.top
                        width: parent.width
                        height: ThemeModule.Theme.separatorThickness
                        color: ThemeModule.Theme.separator
                    }

                    WidgetLoader {
                        id: reservedBottomPanelLoader

                        anchors.top: reservedAreaDivider.bottom
                        anchors.topMargin: ThemeModule.Theme.spacingLarge
                        width: parent.width
                        name: dashboard.activeBottomPanel
                        config: dashboard.config
                        presented: dashboard.presented
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

                T.ScrollBar.vertical: Components.StyledScrollBar {
                    policy: middleFlickable.needsVerticalScroll ? T.ScrollBar.AsNeeded : T.ScrollBar.AlwaysOff
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

                    WidgetLoader {
                        id: activePanelLoader
                        width: parent.width
                        name: dashboard.isWidgetAvailable(dashboard.activePanel) ? dashboard.activePanel : ""
                        config: dashboard.config
                        presented: dashboard.presented
                    }
                }
            }
        }
    }

    // The theme effects' interactions over the panel.
    InteractionsLayer {
        z: 200
        anchors.fill: parent
        host: dashboard
        presented: dashboard.presented
    }
}
