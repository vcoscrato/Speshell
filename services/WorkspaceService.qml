pragma Singleton
// qmllint disable signal-handler-parameters
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Hyprland's regular workspaces on the focused monitor and the apps on each, for the
// dashboard's overview, and the dispatch that shows one. State comes from
// hyprctl and refreshes on Hyprland's events while the dashboard is visible.
Singleton {
    id: root

    readonly property bool watching: DashboardService.workspaceVisible
    // overview()'s list, by id.
    property var workspaces: []
    // What `workspaces` was read from, so an unchanged read leaves the model, and the
    // tiles drawn from it, alone.
    property string lastRead: ""
    property bool refreshQueued: false

    // Events after which the overview may have changed.
    readonly property var refreshEvents: [
        "openwindow", "closewindow", "movewindow", "movewindowv2", "workspace", "workspacev2",
        "createworkspace", "createworkspacev2", "destroyworkspace", "destroyworkspacev2",
        "moveworkspace", "moveworkspacev2", "focusedmon", "focusedmonv2", "activewindowv2",
        "renameworkspace", "changefloatingmode"
    ]

    function refresh() {
        if (stateProc.running) {
            root.refreshQueued = true;
            return;
        }
        stateProc.running = true;
    }

    // The regular workspaces on `monitorName` (all monitors when empty) from hyprctl's
    // -j monitors, workspaces, and clients, in id order. The monitor's active workspace
    // is listed even when empty. Each workspace is { id, name, active, apps, title }:
    // apps are its window classes, each once, tiled before floating and in reading
    // order, and title is that of its last focused window.
    function overview(monitors, workspaces, clients, monitorName) {
        var activeIds = ({});
        (monitors || []).forEach(function(monitor) {
            if (monitor.activeWorkspace)
                activeIds[monitor.name] = monitor.activeWorkspace.id;
        });
        var target = monitorName || "";

        var byId = ({});
        var result = [];
        var add = function(id, name, monitor) {
            if (byId[id] || id <= 0 || (target !== "" && monitor !== target))
                return;
            byId[id] = { id: id, name: String(name || id), active: activeIds[monitor] === id,
                         apps: [], title: "", focus: Infinity };
            result.push(byId[id]);
        };
        (workspaces || []).forEach(function(ws) { add(ws.id, ws.name, ws.monitor); });
        (monitors || []).forEach(function(monitor) {
            if (monitor.activeWorkspace)
                add(monitor.activeWorkspace.id, monitor.activeWorkspace.name, monitor.name);
        });

        var windows = (clients || []).filter(function(client) {
            return client.mapped !== false && client.workspace && byId[client.workspace.id];
        });
        // Tiled before floating, each in reading order: top to bottom, then left to right.
        windows.sort(function(a, b) {
            if (!!a.floating !== !!b.floating)
                return a.floating ? 1 : -1;
            var ay = a.at ? a.at[1] : 0, by = b.at ? b.at[1] : 0;
            var ax = a.at ? a.at[0] : 0, bx = b.at ? b.at[0] : 0;
            return ay !== by ? ay - by : ax - bx;
        });
        windows.forEach(function(client) {
            var ws = byId[client.workspace.id];
            var appClass = String(client["class"] || client.initialClass || "");
            if (appClass !== "" && ws.apps.indexOf(appClass) < 0)
                ws.apps.push(appClass);
            var history = client.focusHistoryID !== undefined ? client.focusHistoryID : Infinity;
            if (ws.title === "" || history < ws.focus) {
                ws.focus = history;
                ws.title = String(client.title || appClass);
            }
        });

        result.sort(function(a, b) { return a.id - b.id; });
        result.forEach(function(ws) { delete ws.focus; });
        return result.filter(function(ws) { return ws.apps.length > 0 || ws.active; });
    }

    function apply(text) {
        var parts = String(text || "").split("\u001e");
        var monitorName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        try {
            const list = root.overview(JSON.parse(parts[0]), JSON.parse(parts[1]),
                                       JSON.parse(parts[2]), monitorName);
            const read = JSON.stringify(list);
            if (read !== root.lastRead) {
                root.lastRead = read;
                root.workspaces = list;
            }
        } catch (error) {
            console.warn("[Speshell] Failed to read Hyprland workspaces:", error);
        }
    }

    // An icon path for a window class: its desktop entry's icon, else a theme icon of
    // that name, else "". Bindings calling it update once desktop entries load.
    function iconFor(appClass) {
        var name = String(appClass || "");
        if (name === "")
            return "";
        var entries = DesktopEntries.applications.values;
        var entry = entries.length > 0 ? DesktopEntries.heuristicLookup(name) : null;
        if (!entry) {
            // Classes such as "dota2" often match an entry's name ("Dota 2") once
            // spaces and punctuation are gone.
            const compactName = function(value) {
                return String(value || "").toLowerCase().replace(/[^a-z0-9]/g, "");
            };
            const compact = compactName(name);
            entry = entries.find(function(candidate) {
                return compactName(candidate.name) === compact;
            }) || null;
        }
        return Quickshell.iconPath(entry && entry.icon ? entry.icon : name.toLowerCase(), true);
    }

    function dispatch(argument) {
        Quickshell.execDetached(["hyprctl", "dispatch", argument]);
    }

    // Shows the workspace under the dashboard. Hyprland keeps a special workspace open
    // across this, but closes it when a window outside it takes focus, so the overview
    // never focuses windows.
    function focusWorkspace(id) {
        root.dispatch(Hyprland.usingLua ? "hl.dsp.focus({ workspace = " + Number(id) + " })" : "workspace " + Number(id));
    }

    onWatchingChanged: if (root.watching) root.refresh()
    Component.onCompleted: if (root.watching) root.refresh()

    Timer {
        id: refreshTimer
        interval: 60
        onTriggered: root.refresh()
    }

    Process {
        id: stateProc
        command: ["sh", "-c", "hyprctl -j monitors; printf '\\036'; hyprctl -j workspaces; printf '\\036'; hyprctl -j clients"]
        stdout: StdioCollector {
            onStreamFinished: root.apply(text)
        }
        onExited: {
            if (root.refreshQueued) {
                root.refreshQueued = false;
                refreshTimer.restart();
            }
        }
    }

    Connections {
        target: Hyprland
        enabled: root.watching

        function onRawEvent(event) {
            if (root.refreshEvents.indexOf(event.name) >= 0)
                refreshTimer.restart();
        }
    }
}
