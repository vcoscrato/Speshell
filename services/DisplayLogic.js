.pragma library

function monitorName(monitor) {
    return monitor && monitor.name ? String(monitor.name) : "";
}

function monitorScale(monitor) {
    var scale = monitor && monitor.scale !== undefined ? Number(monitor.scale) : 1;
    return scale > 0 ? scale : 1;
}

function formatModeRefresh(refreshRate) {
    var refresh = Number(refreshRate) || 0;
    return refresh > 0 ? refresh.toFixed(2) : "";
}

function parseMode(mode) {
    var raw = String(mode || "").trim();
    var match = raw.match(/^([0-9]+)x([0-9]+)@([0-9.]+)\s*(Hz)?$/i);
    if (!match)
        return null;

    var width = parseInt(match[1], 10);
    var height = parseInt(match[2], 10);
    var refreshRate = Number(match[3]) || 0;
    if (width <= 0 || height <= 0 || refreshRate <= 0)
        return null;
    return { width: width, height: height, refreshRate: refreshRate };
}

function normalizeMode(mode) {
    var raw = String(mode || "").trim();
    if (raw === "")
        return "";
    var parsed = parseMode(raw);
    if (!parsed)
        return raw;
    return parsed.width + "x" + parsed.height + "@" + formatModeRefresh(parsed.refreshRate) + "Hz";
}

function modeLabel(mode) {
    var parsed = parseMode(mode);
    if (!parsed)
        return String(mode || "Preferred");
    var rounded = Math.round(parsed.refreshRate);
    var refresh = Math.abs(parsed.refreshRate - rounded) < 0.01
        ? String(rounded)
        : parsed.refreshRate.toFixed(2);
    return parsed.width + "x" + parsed.height + "@" + refresh + "Hz";
}

function modeCommand(mode) {
    var normalized = normalizeMode(mode);
    return normalized === "" ? "preferred" : normalized.replace(/Hz$/i, "");
}

function luaQuote(value) {
    return "\"" + String(value || "")
        .replace(/\\/g, "\\\\")
        .replace(/\"/g, "\\\"")
        .replace(/\r/g, "\\r")
        .replace(/\n/g, "\\n") + "\"";
}

function monitorModeString(monitor) {
    if (monitor && monitor.mode)
        return normalizeMode(monitor.mode);
    var width = Number(monitor && monitor.width) || 0;
    var height = Number(monitor && monitor.height) || 0;
    var refresh = Number(monitor && monitor.refreshRate) || 0;
    if (width <= 0 || height <= 0 || refresh <= 0)
        return "preferred";
    return width + "x" + height + "@" + formatModeRefresh(refresh) + "Hz";
}

function logicalWidth(monitor) {
    return Math.max(1, Math.round((Number(monitor && monitor.width) || 1) / monitorScale(monitor)));
}

function logicalHeight(monitor) {
    return Math.max(1, Math.round((Number(monitor && monitor.height) || 1) / monitorScale(monitor)));
}

function buildActiveMonitors(source) {
    var result = [];
    var list = source || [];
    for (var i = 0; i < list.length; i++) {
        if (list[i] && !list[i].disabled)
            result.push(list[i]);
    }
    return result;
}

function detectMirrored(source) {
    var active = buildActiveMonitors(source || []);
    var occupiedPositions = {};
    for (var i = 0; i < active.length; i++) {
        var mirrorOf = String(active[i].mirrorOf || "");
        if (mirrorOf !== "" && mirrorOf !== "none")
            return true;
        var positionKey = Math.round(Number(active[i].x) || 0)
            + "x" + Math.round(Number(active[i].y) || 0);
        if (occupiedPositions[positionKey])
            return true;
        occupiedPositions[positionKey] = true;
    }
    return false;
}

function detectLayoutMode(source) {
    var active = buildActiveMonitors(source || []);
    if (active.length <= 1)
        return "single";
    return detectMirrored(source || []) ? "mirror" : "extend";
}

function commandForMonitorMode(monitor, position, mirrorTarget) {
    var name = monitorName(monitor);
    if (name === "")
        return "";
    var command = "hl.monitor({ output = " + luaQuote(name)
        + ", mode = " + luaQuote(modeCommand(monitorModeString(monitor)))
        + ", position = " + luaQuote(position)
        + ", scale = " + monitorScale(monitor);
    if (mirrorTarget && mirrorTarget !== "")
        command += ", mirror = " + luaQuote(mirrorTarget);
    return command + " })";
}

function commandForDraftMonitor(monitor) {
    if (!monitor || monitorName(monitor) === "")
        return "";
    if (monitor.disabled)
        return "hl.monitor({ output = " + luaQuote(monitorName(monitor)) + ", disabled = true })";
    var mirrorTarget = String(monitor.mirrorOf || "");
    var position = mirrorTarget !== "" && mirrorTarget !== "none"
        ? "0x0"
        : Math.round(Number(monitor.x) || 0) + "x" + Math.round(Number(monitor.y) || 0);
    return commandForMonitorMode(monitor, position, mirrorTarget);
}

function commandsForMonitors(source, currentMonitors, connectedOnly) {
    var commands = [];
    var connectedNames = ({});
    if (connectedOnly) {
        var current = currentMonitors || [];
        for (var currentIndex = 0; currentIndex < current.length; currentIndex++)
            connectedNames[monitorName(current[currentIndex])] = true;
    }
    var monitorsToApply = source || [];
    for (var i = 0; i < monitorsToApply.length; i++) {
        var name = monitorName(monitorsToApply[i]);
        if (connectedOnly && !connectedNames[name])
            continue;
        commands.push(commandForDraftMonitor(monitorsToApply[i]));
    }
    return commands;
}
