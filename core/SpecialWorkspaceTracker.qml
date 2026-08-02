// qmllint disable signal-handler-parameters
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: root

    property bool enabled: true
    property string workspaceName: "special:term"
    property bool active: false
    property string monitorName: ""
    property bool refreshQueued: false
    readonly property var screen: root.screenForMonitor(root.monitorName)

    function canonicalWorkspaceName(name) {
        var value = String(name || "");
        if (value === "")
            return "";
        return value.indexOf("special:") === 0 ? value : "special:" + value;
    }

    function matchesWorkspace(name) {
        return root.canonicalWorkspaceName(name) === root.canonicalWorkspaceName(root.workspaceName);
    }

    function screenForMonitor(name) {
        for (var i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === name)
                return Quickshell.screens[i];
        }
        return null;
    }

    function setInactive() {
        root.active = false;
        root.monitorName = "";
    }

    function applyMonitorState(monitors) {
        var match = null;
        for (var i = 0; i < monitors.length; i++) {
            var monitor = monitors[i];
            var special = monitor.specialWorkspace || {};
            if (root.matchesWorkspace(special.name)) {
                match = monitor;
                if (monitor.focused)
                    break;
            }
        }

        if (match) {
            root.monitorName = String(match.name || "");
            root.active = root.monitorName !== "";
        } else {
            root.setInactive();
        }
    }

    function refresh() {
        if (!root.enabled)
            return;
        if (monitorProc.running) {
            root.refreshQueued = true;
            return;
        }
        monitorProc.running = true;
    }

    function queueRefresh() {
        if (root.enabled)
            refreshTimer.restart();
    }

    onEnabledChanged: {
        if (root.enabled) {
            root.queueRefresh();
        } else {
            root.setInactive();
        }
    }

    onWorkspaceNameChanged: root.queueRefresh()

    Component.onCompleted: root.queueRefresh()

    Timer {
        id: refreshTimer
        interval: 25
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: monitorProc
        command: ["hyprctl", "monitors", "-j"]
        running: false

        stdout: StdioCollector {
            id: monitorOutput
        }

        onExited: {
            try {
                var monitors = JSON.parse(monitorOutput.text || "[]");
                root.applyMonitorState(Array.isArray(monitors) ? monitors : []);
            } catch (error) {
                console.warn("[Speshell] Failed to read Hyprland special workspace state:", error);
                root.setInactive();
            }

            if (root.refreshQueued) {
                root.refreshQueued = false;
                refreshTimer.restart();
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "activespecial"
                    || event.name === "activespecialv2"
                    || event.name === "monitoradded"
                    || event.name === "monitoraddedv2"
                    || event.name === "monitorremoved") {
                root.queueRefresh();
            }
        }
    }
}
