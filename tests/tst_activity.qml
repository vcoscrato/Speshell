import QtQuick
import QtTest
import "../services/ActivityLogic.js" as ActivityLogic

TestCase {
    name: "ActivityLogic"

    function test_normalizeEntry() {
        var entry = ActivityLogic.normalizeEntry("process", {
            id: "screen-recording",
            state: "active",
            label: "Screen recording",
            tone: "error",
            actions: [{ id: "stop", label: "Stop" }]
        }, null, 1000);

        compare(entry.key, "process:screen-recording");
        compare(entry.startedAt, 1000);
        compare(entry.actions.length, 1);
        compare(entry.actions[0].id, "stop");
        compare(ActivityLogic.normalizeEntry("ipc", {
            id: "bad id",
            state: "active"
        }, null, 1000), null);
        compare(ActivityLogic.normalizeEntry("ipc", {
            id: "sync",
            state: "stopped"
        }, null, 1000), null);
    }

    function test_preservesStartAcrossStateChanges() {
        var active = ActivityLogic.normalizeEntry("process", {
            id: "dictation",
            state: "active"
        }, null, 1000);
        var busy = ActivityLogic.normalizeEntry("process", {
            id: "dictation",
            state: "busy"
        }, active, 5000);

        compare(busy.startedAt, 1000);
        compare(busy.updatedAt, 5000);
    }

    function test_rejectsUnknownState() {
        compare(ActivityLogic.normalizedState("queued"), "");
        compare(ActivityLogic.normalizedState("complete"), "inactive");
    }

    function test_providerPriorityAndOrdering() {
        var processEntry = ActivityLogic.normalizeEntry("process", {
            id: "capture",
            state: "active",
            label: "Detected capture",
            priority: 10,
            sortOrder: 2
        }, null, 1000);
        var ipcEntry = ActivityLogic.normalizeEntry("ipc", {
            id: "capture",
            state: "busy",
            label: "Published capture",
            priority: 50,
            sortOrder: 2
        }, null, 900);
        var firstEntry = ActivityLogic.normalizeEntry("process", {
            id: "recording",
            state: "active",
            priority: 10,
            sortOrder: 1
        }, null, 1200);

        var result = ActivityLogic.flattenProviders({
            process: { capture: processEntry, recording: firstEntry },
            ipc: { capture: ipcEntry }
        });
        compare(result.length, 2);
        compare(result[0].id, "recording");
        compare(result[1].label, "Published capture");
    }

    function test_elapsedText() {
        compare(ActivityLogic.elapsedText(0, 59000), "59s");
        compare(ActivityLogic.elapsedText(0, 125000), "2m 5s");
        compare(ActivityLogic.elapsedText(0, 7380000), "2h 3m");
    }

    function test_detectProcessActivities() {
        compare(ActivityLogic.detectProcessActivities("").length, 0);

        var recording = ActivityLogic.detectProcessActivities("/usr/bin/wf-recorder -f out.mp4\nnvim ~/.local/bin/dictate-toggle\n");
        compare(recording.length, 1);
        compare(recording[0].id, "screen-recording");

        var listening = ActivityLogic.detectProcessActivities("pw-record --channels=1 /tmp/dictate.wav");
        compare(listening[0].state, "active");

        var toggling = ActivityLogic.detectProcessActivities("bash /home/user/.local/bin/dictate-toggle");
        compare(toggling[0].state, "busy");

        var transcribing = ActivityLogic.detectProcessActivities("whisper-cli -m base.bin -f /tmp/dictate.wav");
        compare(transcribing[0].state, "busy");

        compare(ActivityLogic.detectProcessActivities("less wf-recorder.log\npw-record /tmp/other.wav").length, 0);
    }
}
