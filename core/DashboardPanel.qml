// qmllint disable uncreatable-type unqualified unresolved-type
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property var config: null
    property bool workspaceVisible: false
    property var targetScreen: null
    readonly property bool presented: root.visible && root.backingWindowVisible
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

    margins {
        left: root.panelMargin
        top: root.panelMargin
        bottom: root.panelMargin
    }

    Dashboard {
        anchors.fill: parent
        config: root.config
        presented: root.presented
    }
}
