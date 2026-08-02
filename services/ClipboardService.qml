pragma Singleton
// qmllint disable signal-handler-parameters
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var history: []
    property bool panelVisible: false
    property bool loading: false
    property bool available: true
    property bool liveUpdatesAvailable: true
    property int maxItems: 40
    property bool refreshQueued: false
    property bool queuedLoadingIndicator: false
    property string feedbackText: ""
    property string feedbackTone: "neutral"
    property string lastCopiedId: ""
    property string pendingCopyId: ""
    readonly property string liveUpdateWarning: "Live clipboard updates are unavailable."

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
    }

    function startWatching() {
        if (!clipboardWatchProc.running) {
            clipboardWatchProc.running = true;
        }
    }

    function setPanelVisible(visible) {
        if (root.panelVisible === visible)
            return;

        root.panelVisible = visible;
        if (visible) {
            root.refresh(false);
        } else {
            clipboardChangeDebounce.stop();
        }
    }

    // Own the cliphist writer so clipboard history works without a separately
    // configured session service. The child prints only after storage succeeds.
    Timer {
        id: clipboardChangeDebounce
        interval: 200
        running: false
        repeat: false
        onTriggered: root.refresh(false)
    }

    Timer {
        id: watcherRetryTimer
        interval: 30000
        running: false
        repeat: false
        onTriggered: root.startWatching()
    }

    Process {
        id: clipboardWatchProc
        command: [
            "sh",
            "-c",
            "command -v wl-paste >/dev/null 2>&1 "
                + "&& command -v cliphist >/dev/null 2>&1 "
                + "&& exec wl-paste --watch sh -c 'cliphist store && printf \\\"%s\\\\n\\\" \\\"$CLIPBOARD_STATE\\\"'"
        ]
        running: false

        stdout: SplitParser {
            onRead: {
                if (root.panelVisible)
                    clipboardChangeDebounce.restart();
            }
        }

        onStarted: {
            root.liveUpdatesAvailable = true;
            if (root.feedbackText === root.liveUpdateWarning) {
                root.feedbackText = "";
                root.feedbackTone = "neutral";
            }
        }

        onExited: function(exitCode) {
            root.liveUpdatesAvailable = false;
            if (root.panelVisible) {
                root.feedbackText = root.liveUpdateWarning;
                root.feedbackTone = "warning";
            }
            watcherRetryTimer.restart();
        }
    }

    Component.onCompleted: root.startWatching()

    function refresh(showLoadingIndicator) {
        var showIndicator = showLoadingIndicator === undefined
            ? true
            : Boolean(showLoadingIndicator);

        if (cliphistListProc.running) {
            root.refreshQueued = true;
            root.queuedLoadingIndicator = root.queuedLoadingIndicator || showIndicator;
            if (showIndicator) {
                root.loading = true;
            }
            return;
        }

        root.loading = showIndicator;
        cliphistListProc.running = true;
    }

    Process {
        id: cliphistListProc
        command: ["sh", "-lc", "cliphist list | head -n " + root.maxItems]
        running: false
        
        property string buffer: ""
        
        stdout: SplitParser {
            onRead: function(data) {
                cliphistListProc.buffer += data + "\n";
            }
        }

        onExited: function(exitCode) {
            root.available = exitCode === 0;

            if (exitCode !== 0) {
                root.history = [];
                if (root.panelVisible) {
                    root.feedbackText = "Clipboard history is unavailable.";
                    root.feedbackTone = "warning";
                }
                cliphistListProc.buffer = "";
            } else {
                var lines = cliphistListProc.buffer.split("\n");
                cliphistListProc.buffer = "";
                var newHistory = [];

                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line === "") continue;

                    var tabIndex = line.indexOf("\t");
                    if (tabIndex > 0) {
                        newHistory.push({
                            "id": line.substring(0, tabIndex),
                            "preview": line.substring(tabIndex + 1),
                            "raw": line
                        });
                    }
                }
                root.history = newHistory;
            }

            if (root.refreshQueued) {
                var showIndicator = root.queuedLoadingIndicator;
                root.refreshQueued = false;
                root.queuedLoadingIndicator = false;
                root.refresh(showIndicator);
            } else {
                root.loading = false;
            }
        }
    }

    function copyEntry(entry) {
        if (!entry || !entry.id || copyProc.running) {
            return;
        }

        // cliphist decode expects the full "id\tpreview" line, not just the id
        var fullLine = entry.raw || (entry.id + "\t" + (entry.preview || ""));

        root.pendingCopyId = entry.id;
        root.feedbackText = "Copying…";
        root.feedbackTone = "info";
        copyProc.command = [
            "sh",
            "-lc",
            "printf '%s\\n' " + root.shellQuote(fullLine) + " | cliphist decode | wl-copy"
        ];
        copyProc.running = true;
    }

    function copyText(text) {
        var value = String(text || "");
        if (value === "" || copyProc.running) {
            return;
        }

        root.pendingCopyId = "";
        root.feedbackText = "Copying...";
        root.feedbackTone = "info";
        copyProc.command = [
            "sh",
            "-lc",
            "printf '%s' " + root.shellQuote(value) + " | wl-copy"
        ];
        copyProc.running = true;
    }

    function decodeAndCopy(id) {
        // Find the full entry in history to get the raw line
        for (var i = 0; i < root.history.length; i++) {
            if (root.history[i].id === id) {
                root.copyEntry(root.history[i]);
                return;
            }
        }
        // Fallback: try with id only (may not decode correctly without preview)
        root.copyEntry({ id: id, preview: "", raw: id });
    }

    Process {
        id: copyProc
        running: false
        onExited: function(exitCode) {
            if (exitCode === 0) {
                if (root.pendingCopyId !== "") {
                    root.lastCopiedId = root.pendingCopyId;
                    root.refresh(false);
                }
                root.feedbackText = "Copied to the clipboard.";
                root.feedbackTone = "success";
            } else {
                root.feedbackText = "Copy failed.";
                root.feedbackTone = "error";
            }
            root.pendingCopyId = "";
        }
    }

    function clearHistory() {
        if (clearProc.running) {
            return;
        }

        clearProc.running = true;
    }

    Process {
        id: clearProc
        command: ["sh", "-lc", "cliphist wipe"]
        running: false
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.feedbackText = "";
                root.feedbackTone = "neutral";
                root.history = [];
                root.refresh(false);
            } else {
                root.feedbackText = "Failed to clear history.";
                root.feedbackTone = "error";
            }
        }
    }
}
