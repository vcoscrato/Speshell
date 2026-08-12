import QtQuick
import QtTest
import "../services/DisplayLogic.js" as DisplayLogic

TestCase {
    name: "DisplayService"

    function monitor(name, x, disabled, mirrorOf) {
        return {
            name: name,
            description: name,
            disabled: !!disabled,
            focused: name === "DP-1",
            width: 1920,
            height: 1080,
            refreshRate: 60,
            mode: "1920x1080@60Hz",
            availableModes: ["1920x1080@60Hz"],
            scale: 1,
            x: x || 0,
            y: 0,
            mirrorOf: mirrorOf || ""
        };
    }

    function test_modeParsingAndLabels() {
        var parsed = DisplayLogic.parseMode("2560x1440@143.97Hz");
        compare(parsed.width, 2560);
        compare(parsed.height, 1440);
        compare(parsed.refreshRate, 143.97);
        compare(DisplayLogic.modeLabel("2560x1440@60.00Hz"), "2560x1440@60Hz");
        compare(DisplayLogic.parseMode("preferred"), null);
    }

    function test_commandGeneration() {
        compare(
            DisplayLogic.commandForDraftMonitor(monitor("DP-1", 0, false, "")),
            "hl.monitor({ output = \"DP-1\", mode = \"1920x1080@60.00\", position = \"0x0\", scale = 1 })"
        );
        compare(
            DisplayLogic.commandForDraftMonitor(monitor("HDMI-A-1", 0, false, "DP-1")),
            "hl.monitor({ output = \"HDMI-A-1\", mode = \"1920x1080@60.00\", position = \"0x0\", scale = 1, mirror = \"DP-1\" })"
        );
        compare(
            DisplayLogic.commandForDraftMonitor(monitor("HDMI-A-1", 0, true, "")),
            "hl.monitor({ output = \"HDMI-A-1\", disabled = true })"
        );
    }

    function test_layoutDetection() {
        compare(DisplayLogic.detectLayoutMode([monitor("DP-1", 0, false, "")]), "single");
        compare(DisplayLogic.detectLayoutMode([
            monitor("DP-1", 0, false, ""),
            monitor("HDMI-A-1", 1920, false, "")
        ]), "extend");
        compare(DisplayLogic.detectLayoutMode([
            monitor("DP-1", 0, false, ""),
            monitor("HDMI-A-1", 0, false, "DP-1")
        ]), "mirror");
    }

    function test_connectedRollbackCommandsIgnoreNewTopology() {
        var connected = [monitor("DP-1", 0, false, "")];
        var snapshot = [
            monitor("DP-1", 0, false, ""),
            monitor("HDMI-A-1", 1920, false, "")
        ];
        var commands = DisplayLogic.commandsForMonitors(snapshot, connected, true);
        compare(commands.length, 1);
        verify(commands[0].indexOf('output = "DP-1"') !== -1);
    }
}
