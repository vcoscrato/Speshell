// qmllint disable uncreatable-type unqualified unresolved-type
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services" as Services
import "../theme" as ThemeModule

PanelWindow {
    id: root

    property var config: null
    property bool workspaceVisible: false
    property var targetScreen: null
    readonly property bool presented: root.visible && root.backingWindowVisible
    // The theme effects' entrance, latched when the dashboard maps and dropped when it
    // finishes or the dashboard hides.
    property Component entrance: null
    // Untyped, for the API property only entrances have.
    readonly property var entranceItem: entranceLoader.item
    readonly property int panelMargin: root.config && root.config.panelMargin !== undefined
        ? Math.max(0, root.config.panelMargin)
        : 16

    visible: root.workspaceVisible && root.targetScreen !== null
    screen: root.targetScreen
    implicitWidth: root.config && root.config.panelWidth
        ? root.config.panelWidth
        : 420

    color: "transparent"
    focusable: true
    aboveWindows: true
    // Workspace-specific gaps provide the panel space without resizing other workspaces.
    exclusionMode: ExclusionMode.Ignore
    updatesEnabled: root.visible

    WlrLayershell.namespace: "speshell-dashboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        left: true
        top: true
        bottom: true
    }

    // Quickshell's type info hides the fields of PanelWindow.margins.
    // qmllint disable missing-property
    margins {
        left: root.panelMargin
        top: root.panelMargin
        bottom: root.panelMargin
    }
    // qmllint enable missing-property

    onVisibleChanged: {
        root.endEntrance();
        root.entrance = root.visible ? Services.EffectsService.dashboardTransition : null;
        if (root.entrance)
            entranceSafetyTimer.restart();
    }

    // Loader deletes its old item only later, and until then the item's
    // ShaderEffectSource would keep the panel hidden, leaving a frame that draws neither.
    // So the entrance lets go of the panel first.
    function endEntrance() {
        entranceSafetyTimer.stop();
        if (root.entranceItem)
            root.entranceItem.panel = null;
        root.entrance = null;
    }

    Dashboard {
        id: dashboard
        anchors.fill: parent
        config: root.config
        presented: root.presented
    }

    // Effects entrance (see extras/effects/README.md): draws above the panel and may
    // capture it with a ShaderEffectSource. The panel takes input meanwhile.
    Loader {
        id: entranceLoader
        // EffectClock runs at this speed and frame rate.
        property real timeScale: Services.EffectsService.dashboardSpeed > 0 ? Services.EffectsService.dashboardSpeed : 1
        property int frameRate: Services.EffectsService.frameRate
        z: 2
        anchors.fill: parent
        active: root.entrance !== null
        sourceComponent: root.entrance
    }

    Binding {
        target: entranceLoader.item
        property: "panel"
        value: dashboard
    }

    Binding {
        target: entranceLoader.item
        property: "panelRect"
        value: Qt.rect(0, 0, dashboard.width, dashboard.height)
    }

    Binding {
        target: entranceLoader.item
        property: "theme"
        value: ThemeModule.Theme
    }

    Connections {
        target: entranceLoader.item
        ignoreUnknownSignals: true

        function onFinished() { root.endEntrance(); }
    }

    // An entrance must emit finished(); this bounds a broken one.
    Timer {
        id: entranceSafetyTimer
        interval: Math.round(2500 / Math.max(0.25, entranceLoader.timeScale))
        onTriggered: root.endEntrance()
    }
}
