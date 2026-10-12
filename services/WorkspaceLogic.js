.pragma library

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

// The argument for `hyprctl dispatch` in Lua or classic config syntax.
function focusWorkspace(id, lua) {
    return lua ? "hl.dsp.focus({ workspace = " + Number(id) + " })" : "workspace " + Number(id);
}
