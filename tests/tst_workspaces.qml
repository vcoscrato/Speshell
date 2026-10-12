import QtQuick
import QtTest
import "../services/WorkspaceLogic.js" as WorkspaceLogic

TestCase {
    name: "WorkspaceLogic"

    readonly property var monitors: [
        { name: "DP-2", focused: true, x: 0, y: 0, width: 3840, height: 2160, scale: 2,
          activeWorkspace: { id: 4, name: "4" } },
        { name: "HDMI-A-1", focused: false, activeWorkspace: { id: 7, name: "7" } }
    ]
    readonly property var workspaces: [
        { id: 2, name: "2", monitor: "DP-2" },
        { id: -98, name: "special:term", monitor: "DP-2" },
        { id: 1, name: "1", monitor: "DP-2" },
        { id: 7, name: "7", monitor: "HDMI-A-1" },
        { id: 3, name: "3", monitor: "DP-2" }
    ]
    readonly property var clients: [
        { address: "0xb", "class": "kitty", title: "right", at: [960, 0], size: [960, 1080], workspace: { id: 1 }, focusHistoryID: 1 },
        { address: "0xf", "class": "pavucontrol", title: "float", at: [0, 0], size: [400, 300], floating: true,
          workspace: { id: 1 }, focusHistoryID: 5 },
        { address: "0xa", "class": "helium", title: "left", at: [0, 0], workspace: { id: 1 }, focusHistoryID: 0 },
        { address: "0xg", "class": "kitty", title: "below", at: [960, 540], workspace: { id: 1 }, focusHistoryID: 6 },
        { address: "0xc", "class": "discord", title: "chat", at: [0, 0], workspace: { id: -98 }, focusHistoryID: 2 },
        { address: "0xd", "class": "orca", title: "", initialClass: "orca", at: [0, 0], workspace: { id: 2 }, focusHistoryID: 3 },
        { address: "0xe", "class": "mpv", title: "", at: [0, 0], workspace: { id: 7 }, focusHistoryID: 4 }
    ]

    function test_overviewOnMonitor() {
        var list = WorkspaceLogic.overview(monitors, workspaces, clients, "DP-2");
        // Special workspaces, other monitors, and empty inactive ones are left out;
        // the active one stays even when empty.
        compare(list.map(function(ws) { return ws.id; }), [1, 2, 4]);
        compare(list[2].active, true);
        compare(list[2].apps, []);
        // Each app once, tiled in reading order, then floating.
        compare(list[0].apps, ["helium", "kitty", "pavucontrol"]);
        // The workspace's own last focused window, even when focus is elsewhere.
        compare(list[0].title, "left");
        // A window without a title is named by its class.
        compare(list[1].title, "orca");
    }

    function test_overviewAllMonitors() {
        var list = WorkspaceLogic.overview(monitors, workspaces, clients, "");
        compare(list.map(function(ws) { return ws.id; }), [1, 2, 4, 7]);
        compare(list[3].active, true);
    }

    function test_dispatches() {
        compare(WorkspaceLogic.focusWorkspace(3, true), "hl.dsp.focus({ workspace = 3 })");
        compare(WorkspaceLogic.focusWorkspace(3, false), "workspace 3");
    }
}
