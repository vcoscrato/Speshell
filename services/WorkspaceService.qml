pragma Singleton
// qmllint disable signal-handler-parameters
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "WorkspaceLogic.js" as WorkspaceLogic

// Hyprland's regular workspaces on the focused monitor and the apps on each, for the
// dashboard's overview, and the dispatch that shows one. State comes from
// hyprctl and refreshes on Hyprland's events while the dashboard is visible.
Singleton {
    id: root

    readonly property bool watching: DashboardService.workspaceVisible
    // WorkspaceLogic.overview()'s list, by id.
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

    function apply(text) {
        var parts = String(text || "").split("\u001e");
        var monitorName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        try {
            const list = WorkspaceLogic.overview(JSON.parse(parts[0]), JSON.parse(parts[1]),
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
        var entry = DesktopEntries.applications.values.length > 0 ? DesktopEntries.heuristicLookup(name) : null;
        return Quickshell.iconPath(entry && entry.icon ? entry.icon : name.toLowerCase(), true);
    }

    function dispatch(argument) {
        Quickshell.execDetached(["hyprctl", "dispatch", argument]);
    }

    // Shows the workspace under the dashboard. Hyprland keeps a special workspace open
    // across this, but closes it when a window outside it takes focus, so the overview
    // never focuses windows.
    function focusWorkspace(id) {
        root.dispatch(WorkspaceLogic.focusWorkspace(id, Hyprland.usingLua));
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
