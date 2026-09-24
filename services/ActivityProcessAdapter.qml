// qmllint disable signal-handler-parameters

import QtQuick
import Quickshell
import Quickshell.Io
import "." as Services
import "ActivityLogic.js" as ActivityLogic

// Detects wf-recorder and the dictate-toggle workflow. Polling only runs when
// one of those tools is installed, and slows down while nothing is active.
Scope {
    id: root

    property bool toolsAvailable: false
    property string lastSignature: ""
    property bool anyActive: false

    function applyProbeOutput(value) {
        var entries = ActivityLogic.detectProcessActivities(value);
        var signature = entries.map(function(entry) { return entry.id + ":" + entry.state; }).join(",");
        root.anyActive = entries.length > 0;
        if (signature === root.lastSignature)
            return;
        root.lastSignature = signature;
        Services.ActivityService.replaceProvider("process", entries);
    }

    function refresh() {
        if (root.toolsAvailable && !probeProc.running)
            probeProc.running = true;
    }

    Component.onDestruction: Services.ActivityService.clearProvider("process")

    Process {
        running: true
        command: [
            "sh", "-c",
            "command -v wf-recorder >/dev/null 2>&1 || command -v dictate-toggle >/dev/null 2>&1"
        ]
        onExited: function(exitCode) {
            root.toolsAvailable = exitCode === 0;
            root.refresh();
        }
    }

    Timer {
        interval: root.anyActive ? 1000 : 2000
        repeat: true
        running: root.toolsAvailable
        onTriggered: root.refresh()
    }

    Process {
        id: probeProc

        running: false
        command: ["ps", "-e", "-o", "args="]
        stdout: StdioCollector { id: probeOutput }
        onExited: root.applyProbeOutput(probeOutput.text)
    }

    Connections {
        target: Services.ActivityService

        function onActionRequested(provider, activityId, actionId) {
            if (provider !== "process")
                return;
            if (activityId === "screen-recording" && actionId === "stop")
                Quickshell.execDetached(["pkill", "-SIGINT", "-x", "wf-recorder"]);
            else if (activityId === "dictation" && actionId === "finish")
                Quickshell.execDetached(["dictate-toggle"]);
        }
    }
}
