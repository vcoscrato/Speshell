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
    property int stateRevision: 0
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

    function applySpecialEvent(eventName, eventData) {
        var fields = String(eventData || "").split(",");
        var specialName = eventName === "activespecialv2"
            ? String(fields[1] || "")
            : String(fields[0] || "");
        var monitor = eventName === "activespecialv2"
            ? String(fields[2] || "")
            : String(fields[1] || "");

        root.stateRevision += 1;
        if (!root.enabled)
            return;

        if (root.matchesWorkspace(specialName)) {
            root.monitorName = monitor;
            root.active = monitor !== "";
        } else if (monitor === root.monitorName
                || (specialName === "" && root.monitorName === "")) {
            root.setInactive();
        }
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

    function reconcile() {
        if (!root.enabled)
            return;
        if (monitorProc.running) {
            root.refreshQueued = true;
            return;
        }
        monitorProc.requestRevision = root.stateRevision;
        monitorProc.running = true;
    }

    function queueReconcile() {
        if (root.enabled)
            reconcileTimer.restart();
    }

    onEnabledChanged: {
        root.stateRevision += 1;
        if (root.enabled) {
            root.reconcile();
        } else {
            reconcileTimer.stop();
            root.setInactive();
        }
    }

    onWorkspaceNameChanged: {
        root.stateRevision += 1;
        root.setInactive();
        root.reconcile();
    }

    Component.onCompleted: root.reconcile()

    Timer {
        id: reconcileTimer
        interval: 100
        repeat: false
        onTriggered: root.reconcile()
    }

    Process {
        id: monitorProc

        property int requestRevision: 0

        command: ["hyprctl", "monitors", "-j"]
        running: false

        stdout: StdioCollector {
            id: monitorOutput
        }

        onExited: {
            if (monitorProc.requestRevision === root.stateRevision) {
                try {
                    var monitors = JSON.parse(monitorOutput.text || "[]");
                    root.applyMonitorState(Array.isArray(monitors) ? monitors : []);
                } catch (error) {
                    console.warn("[Speshell] Failed to read Hyprland special workspace state:", error);
                    root.setInactive();
                }
            }

            if (root.refreshQueued) {
                root.refreshQueued = false;
                reconcileTimer.restart();
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "activespecial" || event.name === "activespecialv2") {
                root.applySpecialEvent(event.name, event.data);
                root.queueReconcile();
            } else if (event.name === "monitoradded"
                    || event.name === "monitoraddedv2"
                    || event.name === "monitorremoved"
                    || event.name === "configreloaded") {
                root.stateRevision += 1;
                root.queueReconcile();
            }
        }
    }
}
