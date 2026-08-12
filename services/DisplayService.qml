pragma Singleton
// qmllint disable signal-handler-parameters

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "DisplayLogic.js" as DisplayLogic

Singleton {
    id: root

    // ── State ──────────────────────────────────────────────
    property var monitors: []
    property var draftMonitors: []
    property bool applying: false
    property bool confirming: false
    property bool reverting: false
    property bool loading: false
    property bool hasPending: false
    property string errorText: ""
    property string pendingSummary: ""
    property string selectedName: ""
    property int confirmationSecondsRemaining: 0
    property var rollbackMonitors: []
    property bool rollbackRetryAvailable: false
    property string operationKind: ""
    property bool topologyRollbackQueued: false
    property double topologyEventGraceUntil: 0

    readonly property bool displayEditingLocked: root.applying
        || root.loading
        || root.confirming
        || root.reverting

    readonly property var draftActiveMonitors: root.buildActiveMonitors(root.draftMonitors)
    readonly property string draftLayoutMode: root.detectLayoutMode(root.draftMonitors)

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
    }

    function monitorName(monitor) {
        return DisplayLogic.monitorName(monitor);
    }

    function monitorScale(monitor) {
        return DisplayLogic.monitorScale(monitor);
    }

    function formatModeRefresh(refreshRate) {
        return DisplayLogic.formatModeRefresh(refreshRate);
    }

    function normalizeMode(mode) {
        return DisplayLogic.normalizeMode(mode);
    }

    function parseMode(mode) {
        return DisplayLogic.parseMode(mode);
    }

    function modeLabel(mode) {
        return DisplayLogic.modeLabel(mode);
    }

    function modeCommand(mode) {
        return DisplayLogic.modeCommand(mode);
    }

    function monitorModeString(monitor) {
        return DisplayLogic.monitorModeString(monitor);
    }

    function availableModesFor(monitor) {
        var result = [];
        var seen = {};
        var rawModes = monitor && monitor.availableModes ? monitor.availableModes : [];

        for (var i = 0; i < rawModes.length; i++) {
            var mode = root.normalizeMode(rawModes[i]);
            if (mode !== "" && !seen[mode]) {
                seen[mode] = true;
                result.push(mode);
            }
        }

        var current = root.monitorModeString(monitor);
        if (current !== "" && current !== "preferred" && !seen[current]) {
            result.push(current);
        }

        result.sort(function(a, b) {
            var left = root.parseMode(a);
            var right = root.parseMode(b);
            if (!left || !right) {
                return String(a).localeCompare(String(b));
            }
            if (left.width !== right.width) {
                return right.width - left.width;
            }
            if (left.height !== right.height) {
                return right.height - left.height;
            }
            return right.refreshRate - left.refreshRate;
        });
        return result;
    }

    function modesEquivalent(left, right) {
        return root.normalizeMode(left) === root.normalizeMode(right);
    }

    function logicalWidth(monitor) {
        return DisplayLogic.logicalWidth(monitor);
    }

    function logicalHeight(monitor) {
        return DisplayLogic.logicalHeight(monitor);
    }

    function isActiveMonitor(monitor) {
        return monitor && !monitor.disabled;
    }

    function buildActiveMonitors(source) {
        return DisplayLogic.buildActiveMonitors(source);
    }

    function primaryMonitorObject(source) {
        var active = root.buildActiveMonitors(source || root.monitors);
        if (active.length === 0) {
            var fallback = source || root.monitors;
            return fallback.length > 0 ? fallback[0] : null;
        }

        for (var i = 0; i < active.length; i++) {
            if (active[i].focused) {
                return active[i];
            }
        }

        return active[0];
    }

    function detectMirrored(source) {
        return DisplayLogic.detectMirrored(source || root.monitors);
    }

    function detectLayoutMode(source) {
        return DisplayLogic.detectLayoutMode(source || root.monitors);
    }

    function cloneMonitor(monitor) {
        return {
            name: root.monitorName(monitor),
            description: monitor && monitor.description ? String(monitor.description) : "",
            disabled: !!(monitor && monitor.disabled),
            focused: !!(monitor && monitor.focused),
            width: Number(monitor && monitor.width) || 1,
            height: Number(monitor && monitor.height) || 1,
            refreshRate: Number(monitor && monitor.refreshRate) || 0,
            mode: root.monitorModeString(monitor),
            availableModes: root.availableModesFor(monitor),
            scale: root.monitorScale(monitor),
            x: Number(monitor && monitor.x) || 0,
            y: Number(monitor && monitor.y) || 0,
            mirrorOf: String((monitor && monitor.mirrorOf) || "")
        };
    }

    function cloneMonitors(source) {
        var result = [];
        var list = source || [];
        for (var i = 0; i < list.length; i++) {
            result.push(root.cloneMonitor(list[i]));
        }
        return result;
    }

    function sortMonitors(source) {
        var result = root.cloneMonitors(source);
        result.sort(function(a, b) {
            if (!!a.disabled !== !!b.disabled) {
                return a.disabled ? 1 : -1;
            }
            return root.monitorName(a).localeCompare(root.monitorName(b));
        });
        return result;
    }

    function monitorByName(source, name) {
        var list = source || [];
        var targetName = String(name || "");
        for (var i = 0; i < list.length; i++) {
            if (root.monitorName(list[i]) === targetName) {
                return list[i];
            }
        }
        return null;
    }

    function selectedDraftMonitor() {
        return root.monitorByName(root.draftMonitors, root.selectedName);
    }

    function ensureSelected() {
        if (root.monitorByName(root.draftMonitors, root.selectedName)) {
            return;
        }

        var primary = root.primaryMonitorObject(root.draftMonitors);
        root.selectedName = primary ? root.monitorName(primary) : "";
    }

    function setSelected(name) {
        if (root.monitorByName(root.draftMonitors, name)) {
            root.selectedName = String(name || "");
        }
    }

    function resetDraft() {
        root.draftMonitors = root.cloneMonitors(root.monitors);
        root.hasPending = false;
        root.pendingSummary = "";
        root.ensureSelected();
    }

    function markPending(summary, nextDraft) {
        root.draftMonitors = root.sortMonitors(nextDraft);
        root.hasPending = true;
        root.pendingSummary = summary;
        root.ensureSelected();
    }

    function commandForMonitorMode(monitor, position, mirrorTarget) {
        return DisplayLogic.commandForMonitorMode(monitor, position, mirrorTarget);
    }

    function commandForDraftMonitor(monitor) {
        return DisplayLogic.commandForDraftMonitor(monitor);
    }

    function commandForDisable(monitor) {
        var name = root.monitorName(monitor);
        return name === ""
            ? ""
            : "hl.monitor({ output = " + DisplayLogic.luaQuote(name) + ", disabled = true })";
    }

    function commandsForMonitors(source, connectedOnly) {
        return DisplayLogic.commandsForMonitors(source, root.monitors, connectedOnly);
    }

    function runMonitorCommands(commands, operation) {
        if (applyProc.running) {
            return false;
        }

        var script = "set -e\n";
        var hasCommand = false;
        for (var i = 0; i < commands.length; i++) {
            var command = String(commands[i] || "");
            if (command === "") {
                continue;
            }
            script += "hyprctl eval " + root.shellQuote(command) + "\n";
            hasCommand = true;
        }

        if (!hasCommand) {
            return false;
        }

        applyProc.command = ["sh", "-lc", script];
        applyProc.running = true;
        root.applying = true;
        root.operationKind = operation || "apply";
        root.errorText = "";
        return true;
    }

    function applyDraft() {
        if (!root.hasPending || root.displayEditingLocked) {
            return;
        }

        root.rollbackMonitors = root.cloneMonitors(root.monitors);
        root.rollbackRetryAvailable = false;
        if (!root.runMonitorCommands(root.commandsForMonitors(root.draftMonitors, false), "apply")) {
            root.rollbackMonitors = [];
            root.resetDraft();
        }
    }

    function keepDisplayChanges() {
        if (!root.confirming)
            return;
        confirmationTimer.stop();
        root.confirming = false;
        root.confirmationSecondsRemaining = 0;
        root.rollbackMonitors = [];
        root.rollbackRetryAvailable = false;
        root.errorText = "";
        root.refresh();
    }

    function revertDisplayChanges() {
        if (root.rollbackMonitors.length === 0 || applyProc.running)
            return false;

        confirmationTimer.stop();
        root.confirming = false;
        root.confirmationSecondsRemaining = 0;
        root.reverting = true;
        root.rollbackRetryAvailable = false;
        var commands = root.commandsForMonitors(root.rollbackMonitors, true);
        if (!root.runMonitorCommands(commands, "rollback")) {
            root.reverting = false;
            root.rollbackRetryAvailable = true;
            root.errorText = "Could not start display rollback.";
            return false;
        }
        return true;
    }

    function activeDraftCount() {
        return root.buildActiveMonitors(root.draftMonitors).length;
    }

    function firstOtherActiveDraftMonitor(name) {
        var active = root.buildActiveMonitors(root.draftMonitors);
        var selected = String(name || "");
        for (var i = 0; i < active.length; i++) {
            if (root.monitorName(active[i]) !== selected) {
                return active[i];
            }
        }
        return null;
    }

    function setSelectedEnabled(enabled) {
        var selected = root.selectedDraftMonitor();
        if (!selected) {
            return;
        }
        if (!enabled && root.activeDraftCount() <= 1) {
            return;
        }

        var next = [];
        for (var i = 0; i < root.draftMonitors.length; i++) {
            var monitor = root.cloneMonitor(root.draftMonitors[i]);
            if (root.monitorName(monitor) === root.monitorName(selected)) {
                monitor.disabled = !enabled;
                monitor.mirrorOf = "";
                if (enabled) {
                    var bounds = root.boundsFor(root.buildActiveMonitors(root.draftMonitors));
                    monitor.x = bounds.maxX;
                    monitor.y = bounds.minY;
                }
            }
            next.push(monitor);
        }
        root.markPending((enabled ? "Enable " : "Turn off ") + root.monitorName(selected), next);
    }

    function setSelectedMode(mode) {
        var selected = root.selectedDraftMonitor();
        if (!selected || selected.disabled) {
            return;
        }

        var normalized = root.normalizeMode(mode);
        var parsed = root.parseMode(normalized);
        if (!parsed) {
            return;
        }

        var next = [];
        for (var i = 0; i < root.draftMonitors.length; i++) {
            var monitor = root.cloneMonitor(root.draftMonitors[i]);
            if (root.monitorName(monitor) === root.monitorName(selected)) {
                monitor.mode = normalized;
                monitor.width = parsed.width;
                monitor.height = parsed.height;
                monitor.refreshRate = parsed.refreshRate;
            }
            next.push(monitor);
        }
        root.markPending("Set " + root.monitorName(selected) + " to " + root.modeLabel(normalized), next);
    }

    function arrangeSelected(edge) {
        var selected = root.selectedDraftMonitor();
        if (!selected) {
            return;
        }
        var anchor = root.firstOtherActiveDraftMonitor(root.monitorName(selected));
        if (!anchor) {
            return;
        }

        var selectedName = root.monitorName(selected);
        var anchorName = root.monitorName(anchor);
        var next = [];
        var selectedWidth = root.logicalWidth(selected);
        var selectedHeight = root.logicalHeight(selected);
        var anchorWidth = root.logicalWidth(anchor);
        var anchorHeight = root.logicalHeight(anchor);

        for (var i = 0; i < root.draftMonitors.length; i++) {
            var monitor = root.cloneMonitor(root.draftMonitors[i]);
            if (root.monitorName(monitor) === anchorName) {
                monitor.disabled = false;
                monitor.x = 0;
                monitor.y = 0;
                monitor.mirrorOf = "";
            } else if (root.monitorName(monitor) === selectedName) {
                monitor.disabled = false;
                monitor.mirrorOf = "";
                if (edge === "left") {
                    monitor.x = -selectedWidth;
                    monitor.y = 0;
                } else if (edge === "above") {
                    monitor.x = 0;
                    monitor.y = -selectedHeight;
                } else if (edge === "below") {
                    monitor.x = 0;
                    monitor.y = anchorHeight;
                } else {
                    monitor.x = anchorWidth;
                    monitor.y = 0;
                }
            }
            next.push(monitor);
        }
        root.markPending("Place " + selectedName + " " + edge + " of " + anchorName, next);
    }

    function useOnlySelected() {
        var selected = root.selectedDraftMonitor();
        if (!selected) {
            return;
        }

        var selectedName = root.monitorName(selected);
        var next = [];
        for (var i = 0; i < root.draftMonitors.length; i++) {
            var monitor = root.cloneMonitor(root.draftMonitors[i]);
            monitor.disabled = root.monitorName(monitor) !== selectedName;
            if (!monitor.disabled) {
                monitor.x = 0;
                monitor.y = 0;
                monitor.mirrorOf = "";
            }
            next.push(monitor);
        }
        root.markPending("Use only " + selectedName, next);
    }

    function setDraftLayoutMode(mode) {
        var selected = root.selectedDraftMonitor();
        if (!selected) {
            return;
        }

        var selectedName = root.monitorName(selected);
        var nextMode = String(mode || "");
        if (nextMode === "single") {
            root.useOnlySelected();
            return;
        }

        var next = [];
        var offsetX = root.logicalWidth(selected);
        for (var i = 0; i < root.draftMonitors.length; i++) {
            var monitor = root.cloneMonitor(root.draftMonitors[i]);
            var name = root.monitorName(monitor);
            monitor.disabled = false;

            if (name === selectedName) {
                monitor.x = 0;
                monitor.y = 0;
                monitor.mirrorOf = "";
            } else if (nextMode === "mirror") {
                monitor.x = 0;
                monitor.y = 0;
                monitor.mirrorOf = selectedName;
            } else {
                monitor.x = offsetX;
                monitor.y = 0;
                monitor.mirrorOf = "";
                offsetX += root.logicalWidth(monitor);
            }

            next.push(monitor);
        }

        root.markPending(nextMode === "mirror" ? "Mirror displays" : "Extend displays", next);
    }

    function boundsFor(source) {
        var active = root.buildActiveMonitors(source || []);
        if (active.length === 0) {
            return { minX: 0, minY: 0, maxX: 1, maxY: 1, width: 1, height: 1 };
        }

        var minX = Number(active[0].x) || 0;
        var minY = Number(active[0].y) || 0;
        var maxX = minX + root.logicalWidth(active[0]);
        var maxY = minY + root.logicalHeight(active[0]);

        for (var i = 1; i < active.length; i++) {
            var monitor = active[i];
            var x = Number(monitor.x) || 0;
            var y = Number(monitor.y) || 0;
            minX = Math.min(minX, x);
            minY = Math.min(minY, y);
            maxX = Math.max(maxX, x + root.logicalWidth(monitor));
            maxY = Math.max(maxY, y + root.logicalHeight(monitor));
        }

        return {
            minX: minX,
            minY: minY,
            maxX: maxX,
            maxY: maxY,
            width: Math.max(1, maxX - minX),
            height: Math.max(1, maxY - minY)
        };
    }

    function activeMonitorIndex(source, monitor) {
        var targetName = root.monitorName(monitor);
        var active = root.buildActiveMonitors(source || []);
        for (var i = 0; i < active.length; i++) {
            if (root.monitorName(active[i]) === targetName) {
                return i;
            }
        }
        return -1;
    }

    function mapRect(monitor, canvasWidth, canvasHeight) {
        if (!monitor || monitor.disabled) {
            return { x: 0, y: 0, width: 0, height: 0 };
        }

        var padding = 10;
        var availableWidth = Math.max(1, canvasWidth - padding * 2);
        var availableHeight = Math.max(1, canvasHeight - padding * 2);
        var active = root.buildActiveMonitors(root.draftMonitors);

        if (root.detectLayoutMode(root.draftMonitors) === "mirror" && active.length > 1) {
            var index = Math.max(0, root.activeMonitorIndex(active, monitor));
            var slotWidth = availableWidth / active.length;
            var mirrorScale = Math.min(
                Math.max(1, slotWidth - 6) / root.logicalWidth(monitor),
                availableHeight / root.logicalHeight(monitor)
            );
            var mirrorWidth = Math.max(34, root.logicalWidth(monitor) * mirrorScale);
            var mirrorHeight = Math.max(24, root.logicalHeight(monitor) * mirrorScale);
            return {
                x: padding + index * slotWidth + Math.max(0, (slotWidth - mirrorWidth) / 2),
                y: padding + Math.max(0, (availableHeight - mirrorHeight) / 2),
                width: mirrorWidth,
                height: mirrorHeight
            };
        }

        var bounds = root.boundsFor(root.draftMonitors);
        var scale = Math.min(availableWidth / bounds.width, availableHeight / bounds.height);
        var width = Math.max(34, root.logicalWidth(monitor) * scale);
        var height = Math.max(24, root.logicalHeight(monitor) * scale);
        return {
            x: padding + ((Number(monitor.x) || 0) - bounds.minX) * scale,
            y: padding + ((Number(monitor.y) || 0) - bounds.minY) * scale,
            width: width,
            height: height
        };
    }

    // ── Actions ────────────────────────────────────────────
    function refresh() {
        if (!monitorsProc.running) {
            root.loading = true;
            monitorsProc.running = true;
        }
    }

    function queueRefresh() {
        if (!root.hasPending && !root.applying && !root.loading) {
            refreshDebounce.restart();
        }
    }

    Timer {
        id: refreshDebounce
        interval: 250
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: confirmationTimer
        interval: 1000
        repeat: true
        onTriggered: {
            root.confirmationSecondsRemaining--;
            if (root.confirmationSecondsRemaining <= 0)
                root.revertDisplayChanges();
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "monitoradded"
                    || event.name === "monitoraddedv2"
                    || event.name === "monitorremoved") {
                Hyprland.refreshMonitors();
                if (root.confirming) {
                    if (Date.now() < root.topologyEventGraceUntil) {
                        root.queueRefresh();
                        return;
                    }
                    confirmationTimer.stop();
                    root.confirming = false;
                    root.confirmationSecondsRemaining = 0;
                    root.topologyRollbackQueued = true;
                    if (!root.loading)
                        root.refresh();
                } else {
                    root.queueRefresh();
                }
            }
        }
    }

    // ── Processes ──────────────────────────────────────────
    Process {
        id: monitorsProc
        command: ["hyprctl", "monitors", "all", "-j"]
        running: false

        stdout: StdioCollector {
            id: monitorsOutput
        }

        stderr: StdioCollector {
            id: monitorsError
        }

        onExited: function(exitCode) {
            root.loading = false;
            try {
                var json = JSON.parse(monitorsOutput.text || "[]");
                if (Array.isArray(json)) {
                    root.monitors = root.sortMonitors(json);
                    if (!root.hasPending) {
                        root.resetDraft();
                    } else {
                        root.ensureSelected();
                    }
                    if (exitCode !== 0)
                        root.errorText = monitorsError.text || "Could not read displays.";
                    else if (!root.rollbackRetryAvailable)
                        root.errorText = "";
                    if (root.topologyRollbackQueued) {
                        root.topologyRollbackQueued = false;
                        Qt.callLater(root.revertDisplayChanges);
                    }
                }
            } catch(e) {
                root.errorText = "Could not read displays.";
                console.warn("[Speshell] Failed to parse hyprctl monitors output:", e);
                if (root.topologyRollbackQueued) {
                    root.topologyRollbackQueued = false;
                    Qt.callLater(root.revertDisplayChanges);
                }
            }
        }
    }

    Process {
        id: applyProc
        running: false
        stderr: StdioCollector {
            id: applyError
        }
        onExited: function(exitCode) {
            var completedOperation = root.operationKind;
            root.operationKind = "";
            root.applying = false;
            if (completedOperation === "rollback") {
                root.reverting = false;
                if (exitCode !== 0) {
                    root.rollbackRetryAvailable = true;
                    root.errorText = applyError.text || "Display rollback failed.";
                } else {
                    root.rollbackMonitors = [];
                    root.rollbackRetryAvailable = false;
                    root.errorText = "";
                }
            } else if (exitCode !== 0) {
                root.rollbackMonitors = [];
                root.errorText = applyError.text || "Display change failed.";
            } else {
                root.hasPending = false;
                root.pendingSummary = "";
                root.confirming = true;
                root.confirmationSecondsRemaining = 15;
                root.topologyEventGraceUntil = Date.now() + 1500;
                confirmationTimer.restart();
            }
            root.refresh();
        }
    }
}
