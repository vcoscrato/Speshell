pragma Singleton
// qmllint disable signal-handler-parameters

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var lockCommand: ["hyprlock"]
    property bool lockerAvailable: false
    property bool lockerChecking: true
    property bool busy: false
    property string activeAction: ""
    property string errorMessage: ""

    property string lockerPurpose: ""

    signal actionCompleted(string action)

    function actionLabel(action) {
        if (action === "lock") return "Lock";
        if (action === "sleep") return "Sleep";
        if (action === "logout") return "Log out";
        if (action === "restart") return "Restart";
        if (action === "poweroff") return "Power off";
        return "Power action";
    }

    function commandError(collector, fallback) {
        var detail = collector && collector.text ? collector.text.trim() : "";
        if (detail === "")
            return fallback;
        var firstLine = detail.split("\n")[0].trim();
        return firstLine !== "" ? firstLine : fallback;
    }

    function clearFeedback() {
        root.errorMessage = "";
    }

    function fail(message) {
        lockerReadyTimer.stop();
        root.busy = false;
        root.activeAction = "";
        root.lockerPurpose = "";
        root.errorMessage = message;
    }

    function finish(action) {
        root.busy = false;
        root.activeAction = "";
        root.lockerPurpose = "";
        root.actionCompleted(action);
    }

    function probeLocker() {
        var command = root.lockCommand || [];
        root.lockerAvailable = false;
        root.lockerChecking = true;

        if (command.length === 0 || String(command[0]).trim() === "") {
            root.lockerChecking = false;
            return;
        }

        if (lockerProbe.running)
            lockerProbe.running = false;
        lockerProbe.command = ["which", String(command[0])];
        lockerProbe.running = true;
    }

    function startLocker(purpose) {
        if (!root.lockerAvailable) {
            root.fail("Screen locker unavailable. Check powerMenu.lockCommand.");
            return false;
        }
        if (lockerProcess.running) {
            root.fail("The configured screen locker is already running.");
            return false;
        }

        root.lockerPurpose = purpose;
        lockerProcess.command = root.lockCommand.slice();
        lockerProcess.running = true;
        lockerReadyTimer.restart();
        return true;
    }

    function runAction(action) {
        if (root.busy)
            return false;

        root.clearFeedback();
        root.busy = true;
        root.activeAction = action;

        if (action === "lock" || action === "sleep") {
            return root.startLocker(action);
        }

        if (action === "logout") {
            actionProcess.command = [
                "sh", "-c",
                "if command -v hyprshutdown >/dev/null 2>&1; then exec hyprshutdown; "
                    + "elif hyprctl status 2>/dev/null | grep -q '^configProvider: lua$'; then "
                    + "exec hyprctl dispatch 'hl.dsp.exit()'; "
                    + "else exec hyprctl dispatch exit; fi"
            ];
        }
        else if (action === "restart")
            actionProcess.command = ["systemctl", "reboot"];
        else if (action === "poweroff")
            actionProcess.command = ["systemctl", "poweroff"];
        else {
            root.fail("Unknown power action: " + action);
            return false;
        }

        actionProcess.running = true;
        return true;
    }

    onLockCommandChanged: probeLocker()

    Timer {
        id: lockerReadyTimer
        interval: 750
        repeat: false
        onTriggered: {
            var purpose = root.lockerPurpose;
            if (!lockerProcess.running) {
                root.fail(root.commandError(
                    lockerError,
                    "The configured screen locker exited before securing the session."
                ));
                return;
            }

            if (purpose === "lock") {
                root.finish("lock");
                return;
            }

            if (purpose === "sleep") {
                suspendProcess.running = true;
            }
        }
    }

    Process {
        id: lockerProbe
        running: false
        onExited: function(exitCode) {
            root.lockerAvailable = exitCode === 0;
            root.lockerChecking = false;
        }
    }

    Process {
        id: lockerProcess
        running: false
        stderr: StdioCollector { id: lockerError }
        onExited: function(exitCode) {
            if (lockerReadyTimer.running && root.lockerPurpose !== "") {
                root.fail(root.commandError(
                    lockerError,
                    "The configured screen locker exited before securing the session."
                ));
            }
        }
    }

    Process {
        id: suspendProcess
        command: ["systemctl", "suspend"]
        running: false
        stderr: StdioCollector { id: suspendError }
        onExited: function(exitCode) {
            if (root.activeAction !== "sleep")
                return;
            if (exitCode === 0)
                root.finish("sleep");
            else
                root.fail(root.commandError(suspendError, "Could not suspend the system."));
        }
    }

    Process {
        id: actionProcess
        running: false
        stderr: StdioCollector { id: actionError }
        onExited: function(exitCode) {
            var action = root.activeAction;
            if (action === "" || action === "lock" || action === "sleep")
                return;
            if (exitCode !== 0) {
                root.fail(root.commandError(
                    actionError,
                    root.actionLabel(action) + " failed."
                ));
                return;
            }
            root.finish(action);
        }
    }

    Component.onCompleted: probeLocker()
}
