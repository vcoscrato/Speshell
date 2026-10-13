// qmllint disable signal-handler-parameters

import QtQuick
import Quickshell
import Quickshell.Io
import "." as Services

// Detects wf-recorder and the dictate-toggle workflow. Polling only runs when
// one of those tools is installed, and slows down while nothing is active.
Scope {
    id: root

    property bool toolsAvailable: false
    property string lastSignature: ""
    property bool anyActive: false
    readonly property var shellNames: ["sh", "bash", "dash", "zsh"]

    function commandName(value) {
        var path = String(value || "");
        return path.substring(path.lastIndexOf("/") + 1);
    }

    // Reads `ps -e -o args=` output. Matching on argv[0] (or the script run by a
    // shell) avoids false positives from editors or pagers that mention a tool.
    function detect(psOutput) {
        var recording = false;
        var dictationToggle = false;
        var dictationRecording = false;
        var dictationTranscribing = false;
        var lines = String(psOutput || "").split("\n");

        for (var i = 0; i < lines.length; i++) {
            var args = lines[i].trim().split(/\s+/);
            var name = root.commandName(args[0]);
            if (root.shellNames.indexOf(name) >= 0 && root.commandName(args[1]) === "dictate-toggle")
                name = "dictate-toggle";
            var dictationFile = lines[i].indexOf("dictate.wav") >= 0;

            if (name === "wf-recorder")
                recording = true;
            else if (name === "dictate-toggle")
                dictationToggle = true;
            else if (name === "pw-record" && dictationFile)
                dictationRecording = true;
            else if (name === "whisper-cli" && dictationFile)
                dictationTranscribing = true;
        }

        var entries = [];
        if (recording) {
            entries.push({
                id: "screen-recording",
                state: "active",
                label: "Screen recording",
                detail: "Recording display",
                iconName: "screen-recording",
                tone: "error",
                priority: 10,
                sortOrder: 0,
                actions: [{ id: "stop", label: "Stop", iconName: "close", tone: "error" }]
            });
        }
        if (dictationTranscribing || (dictationToggle && !dictationRecording)) {
            entries.push({
                id: "dictation",
                state: "busy",
                label: "Dictation",
                detail: "Transcribing…",
                iconName: "loader",
                tone: "info",
                priority: 10,
                sortOrder: 1
            });
        } else if (dictationRecording) {
            entries.push({
                id: "dictation",
                state: "active",
                label: "Dictation",
                detail: "Listening…",
                iconName: "audio-input",
                tone: "info",
                priority: 10,
                sortOrder: 1,
                actions: [{ id: "finish", label: "Finish", iconName: "check", tone: "info" }]
            });
        }
        return entries;
    }

    function applyProbeOutput(value) {
        var entries = root.detect(value);
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
