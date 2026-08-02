pragma Singleton
// qmllint disable signal-handler-parameters

import QtQuick
import Quickshell
import Quickshell.Io
import "../core/WidgetRegistry.js" as WidgetRegistry

Singleton {
    id: root

    property string workspaceName: "special:term"
    property bool workspaceVisible: false
    property string errorMessage: ""
    readonly property var availablePanelNames: root.filterAvailablePanels(
        WidgetRegistry.navigationPanels,
        FeatureSupport.supportsBattery,
        FeatureSupport.supportsBluetooth,
        FeatureSupport.supportsDisplayControl
    )
    signal panelRequested(string panelName)

    function panelSupported(panelName, batterySupported, bluetoothSupported, displaySupported) {
        if (panelName === "batteryStatus")
            return batterySupported;
        if (panelName === "bluetoothPanel")
            return bluetoothSupported;
        if (panelName === "displayControl")
            return displaySupported;
        return true;
    }

    function filterAvailablePanels(panelNames, batterySupported, bluetoothSupported, displaySupported) {
        var result = [];
        var seen = ({});
        var configured = Array.isArray(panelNames) ? panelNames : [];
        for (var i = 0; i < configured.length; i++) {
            var panel = String(configured[i] || "");
            if (!WidgetRegistry.has(panel)
                    || Object.prototype.hasOwnProperty.call(seen, panel)
                    || !root.panelSupported(panel, batterySupported, bluetoothSupported, displaySupported))
                continue;
            seen[panel] = true;
            result.push(panel);
        }
        return result;
    }

    function isPanelAvailable(panelName) {
        return root.availablePanelNames.indexOf(String(panelName || "")) >= 0;
    }

    function workspaceArgument() {
        var value = String(root.workspaceName || "special:term");
        return value.indexOf("special:") === 0 ? value.substring(8) : value;
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
    }

    function luaQuote(value) {
        return "\"" + String(value).replace(/\\/g, "\\\\").replace(/\"/g, "\\\"") + "\"";
    }

    function openPanel(panelName) {
        var supplied = String(panelName || "");
        var requested = WidgetRegistry.canonicalName(supplied);
        if (!WidgetRegistry.has(supplied)) {
            root.errorMessage = "Unknown dashboard panel '" + supplied + "'.";
            return false;
        }
        if (!root.isPanelAvailable(requested)) {
            root.errorMessage = "The " + requested + " panel is not available in the dashboard.";
            return false;
        }
        root.errorMessage = "";
        root.panelRequested(requested);
        if (!root.workspaceVisible && !openWorkspaceProc.running) {
            var workspace = root.workspaceArgument();
            var luaDispatcher = "hl.dsp.workspace.toggle_special(" + root.luaQuote(workspace) + ")";
            openWorkspaceProc.command = [
                "sh", "-c",
                "if hyprctl status 2>/dev/null | grep -q '^configProvider: lua$'; then "
                    + "exec hyprctl dispatch " + root.shellQuote(luaDispatcher) + "; "
                    + "else exec hyprctl dispatch togglespecialworkspace " + root.shellQuote(workspace) + "; fi"
            ];
            openWorkspaceProc.running = true;
        }
        return true;
    }

    Process {
        id: openWorkspaceProc
        running: false
        stderr: StdioCollector { id: openWorkspaceError }
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                var detail = String(openWorkspaceError.text || "").trim();
                root.errorMessage = detail !== "" ? detail : "Could not open the Speshell workspace.";
            }
        }
    }
}
