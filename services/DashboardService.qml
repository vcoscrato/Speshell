pragma Singleton
// qmllint disable signal-handler-parameters

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../core/WidgetRegistry.js" as WidgetRegistry
import "Shell.js" as Shell

Singleton {
    id: root

    property string workspaceName: "special:term"
    property bool workspaceVisible: false
    // Set from the config; until then Speshell leaves the workspace's gaps alone.
    property int panelWidth: 0
    property int panelMargin: 0
    // Space between the panel and the windows beside it.
    readonly property int panelGap: 12
    property string errorMessage: ""
    // A Settings page to show, for when Settings next loads or is showing; it clears this.
    property string settingsPage: ""
    readonly property var availablePanelNames: WidgetRegistry.navigationPanels.filter(function(panel) {
        return root.isPanelSupported(panel);
    })
    // Bar dropdowns open across the screens.
    property int openDropdowns: 0
    signal panelRequested(string panelName)
    // The bars close their dropdowns.
    signal dismissRequested()

    function isPanelSupported(panelName) {
        if (panelName === "batteryStatus")
            return FeatureSupport.supportsBattery;
        if (panelName === "bluetoothPanel")
            return FeatureSupport.supportsBluetooth;
        if (panelName === "displayControl")
            return FeatureSupport.supportsDisplayControl;
        if (panelName === "tools")
            return ToolsService.available;
        return true;
    }

    // Screen for the focused Hyprland monitor, falling back to the first screen.
    function focusedScreen() {
        var name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        for (var i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === name)
                return Quickshell.screens[i];
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function workspaceArgument() {
        var value = String(root.workspaceName || "special:term");
        return value.indexOf("special:") === 0 ? value.substring(8) : value;
    }

    // A panel's state in a few words, for its rail or bar button's tooltip.
    function statusText(panelName) {
        if (panelName === "audioControl")
            return (AudioService.outputDeviceLabel || "Volume") + ": " + AudioService.outputVolumePercent + "%";
        if (panelName === "audioInputControl")
            return (AudioService.inputDeviceLabel || "Mic") + ": " + AudioService.inputVolumePercent + "%";
        if (panelName === "displayControl" && BrightnessService.available)
            return "Brightness: " + BrightnessService.percent + "%";
        if (panelName === "networkPanel") {
            if (NetworkService.wiredDevice)
                return "Ethernet";
            var wifi = NetworkService.connectedWifi;
            if (wifi)
                return "WiFi: " + wifi.name;
            return NetworkService.wifiOn ? "Disconnected" : "WiFi Off";
        }
        if (panelName === "bluetoothPanel")
            return BluetoothService.enabled ? "Bluetooth On" : "Bluetooth Off";
        if (panelName === "clipboardManager") {
            var clipCount = ClipboardService.history.length;
            return clipCount > 0 ? "Clipboard (" + clipCount + " item" + (clipCount === 1 ? "" : "s") + ")" : "Clipboard";
        }
        if (panelName === "themes")
            return "Theme: " + ThemeService.theme.name;
        if (panelName === "tools")
            return ToolsService.statusText;
        return WidgetRegistry.label(panelName);
    }

    // Shows or hides the dashboard's workspace on the focused monitor.
    function toggleWorkspace() {
        if (openWorkspaceProc.running)
            return;
        var workspace = root.workspaceArgument();
        var luaDispatcher = "hl.dsp.workspace.toggle_special(" + Shell.luaQuote(workspace) + ")";
        openWorkspaceProc.command = [
            "sh", "-c",
            "if hyprctl status 2>/dev/null | grep -q '^configProvider: lua$'; then "
                + "exec hyprctl dispatch \"$1\"; "
                + "else exec hyprctl dispatch togglespecialworkspace \"$2\"; fi",
            "speshell-open-workspace",
            luaDispatcher,
            workspace
        ];
        openWorkspaceProc.running = true;
    }

    // Hides the bars' dropdowns, and the dashboard unless `keepWorkspace`, for a tool
    // that captures or types into what's under them. Returns whether any was showing.
    function dismissSurfaces(keepWorkspace) {
        var closesWorkspace = root.workspaceVisible && !keepWorkspace;
        var shown = closesWorkspace || root.openDropdowns > 0;
        root.dismissRequested();
        if (closesWorkspace)
            root.toggleWorkspace();
        return shown;
    }

    function openPanel(panelName) {
        var supplied = String(panelName || "");
        var requested = WidgetRegistry.canonicalName(supplied);
        if (!WidgetRegistry.has(supplied)) {
            root.errorMessage = "Unknown dashboard panel '" + supplied + "'.";
            return false;
        }
        if (root.availablePanelNames.indexOf(requested) < 0) {
            root.errorMessage = "The " + requested + " panel is not available in the dashboard.";
            return false;
        }
        root.errorMessage = "";
        root.panelRequested(requested);
        if (!root.workspaceVisible)
            root.toggleWorkspace();
        return true;
    }

    onWorkspaceNameChanged: root.reserveWorkspaceSpace()
    onPanelWidthChanged: root.reserveWorkspaceSpace()
    onPanelMarginChanged: root.reserveWorkspaceSpace()

    // Sets the workspace's outer gaps so its windows tile beside the panel. Hyprland
    // relayouts the workspace when it is showing, and otherwise when it next shows.
    function reserveWorkspaceSpace() {
        Qt.callLater(root.applyWorkspaceSpace);
    }

    function applyWorkspaceSpace() {
        if (root.panelWidth <= 0)
            return;
        if (reserveSpaceProc.running) {
            reserveSpaceProc.pending = true;
            return;
        }
        var margin = root.panelMargin;
        var left = margin + root.panelWidth + root.panelGap;
        var workspace = "special:" + root.workspaceArgument();
        var luaRule = "hl.workspace_rule({ workspace = " + Shell.luaQuote(workspace)
            + ", gaps_out = { top = " + margin + ", right = " + margin
            + ", bottom = " + margin + ", left = " + left + " } })";
        var legacyRule = workspace + ", gapsout:" + [margin, margin, margin, left].join(" ");
        reserveSpaceProc.command = [
            "sh", "-c",
            "if hyprctl status 2>/dev/null | grep -q '^configProvider: lua$'; then "
                + "exec hyprctl eval \"$1\"; "
                + "else exec hyprctl keyword workspace \"$2\"; fi",
            "speshell-reserve-space",
            luaRule,
            legacyRule
        ];
        reserveSpaceProc.running = true;
    }

    // A config reload restores the workspace rule from the Hyprland config.
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "configreloaded")
                root.reserveWorkspaceSpace();
        }
    }

    Process {
        id: reserveSpaceProc
        property bool pending: false
        running: false
        stdout: StdioCollector { id: reserveSpaceOutput }
        onExited: function(exitCode) {
            if (exitCode !== 0)
                console.warn("[Speshell] Could not reserve dashboard space in Hyprland:",
                    String(reserveSpaceOutput.text || "").trim());
            if (reserveSpaceProc.pending) {
                reserveSpaceProc.pending = false;
                root.applyWorkspaceSpace();
            }
        }
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
