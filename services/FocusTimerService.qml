pragma Singleton

import QtQuick
import Quickshell

// Owns the focus timer countdown and its completion notification.
Singleton {
    id: root

    property bool running: false
    property int totalSeconds: 0
    property int remainingSeconds: 0
    property double endsAtMs: 0
    readonly property real progress: root.totalSeconds > 0
        ? root.remainingSeconds / root.totalSeconds
        : 0

    function wholeMinutes(minutes) {
        return Math.max(1, Math.round(Number(minutes) || 0));
    }

    function start(minutes) {
        root.totalSeconds = root.wholeMinutes(minutes) * 60;
        root.remainingSeconds = root.totalSeconds;
        root.endsAtMs = Date.now() + root.totalSeconds * 1000;
        root.running = true;
    }

    function stop() {
        root.running = false;
        root.endsAtMs = 0;
        root.totalSeconds = 0;
        root.remainingSeconds = 0;
    }

    // Extends a running timer, or starts one when idle.
    function addMinutes(minutes) {
        if (!root.running) {
            root.start(minutes);
            return;
        }

        var extra = root.wholeMinutes(minutes) * 60;
        root.totalSeconds += extra;
        root.endsAtMs += extra * 1000;
        root.updateCountdown();
    }

    function updateCountdown() {
        if (!root.running)
            return;

        root.remainingSeconds = Math.max(0, Math.ceil((root.endsAtMs - Date.now()) / 1000));
        if (root.remainingSeconds > 0)
            return;

        root.stop();
        Quickshell.execDetached(["notify-send", "-a", "Speshell", "-u", "critical", "Timer Done", "Your timer has finished."]);
    }

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateCountdown()
    }
}
