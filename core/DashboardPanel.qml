// qmllint disable uncreatable-type unqualified unresolved-type
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root

    property var config: null
    property bool workspaceVisible: false
    property bool focusGrabActive: false
    property var targetScreen: null
    readonly property bool mapped: root.visible && root.backingWindowVisible
    readonly property bool presented: root.mapped
    readonly property int panelMargin: root.config && root.config.panelMargin !== undefined
        ? Math.max(0, root.config.panelMargin)
        : 16

    function scheduleFocusGrab() {
        if (!root.mapped)
            return;

        root.focusGrabActive = false;
        focusReleaseTimer.stop();
        focusGrabTimer.restart();
    }

    function releaseFocusGrab() {
        focusGrabTimer.stop();
        focusReleaseTimer.stop();
        root.focusGrabActive = false;
    }

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

    HyprlandFocusGrab {
        active: root.focusGrabActive
        windows: [root]

        onCleared: root.releaseFocusGrab()
    }

    onVisibleChanged: {
        if (root.visible)
            root.scheduleFocusGrab();
        else
            root.releaseFocusGrab();
    }
    onBackingWindowVisibleChanged: {
        if (root.mapped)
            root.scheduleFocusGrab();
        else
            root.releaseFocusGrab();
    }
    onScreenChanged: {
        if (root.visible)
            root.scheduleFocusGrab();
    }

    Timer {
        id: focusGrabTimer
        interval: 60
        repeat: false
        onTriggered: {
            if (!root.mapped)
                return;

            var panelWindow = dashboardContent.Window.window;
            if (!panelWindow || !panelWindow.activeFocusItem)
                dashboardContent.forceActiveFocus();
            root.focusGrabActive = true;
            focusReleaseTimer.restart();
        }
    }

    Timer {
        id: focusReleaseTimer
        interval: 250
        repeat: false
        onTriggered: {
            root.focusGrabActive = false;
        }
    }

    anchors {
        left: true
        top: true
        bottom: true
    }

    margins {
        left: root.panelMargin
        top: root.panelMargin
        bottom: root.panelMargin
    }

    Dashboard {
        id: dashboardContent
        anchors.fill: parent
        focus: true
        config: root.config
        presented: root.presented
    }
}
