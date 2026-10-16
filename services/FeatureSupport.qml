pragma Singleton
// qmllint disable unresolved-type

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.UPower

Singleton {
    id: root

    property bool brightnessHelperAvailable: false
    property bool hyprctlAvailable: false
    property bool curlAvailable: false
    property bool backlightProbeComplete: false
    property bool toolProbeComplete: false
    property var backlightDevices: []
    property string configuredBacklightDevice: ""
    readonly property string backlightDeviceName: {
        if (root.configuredBacklightDevice !== ""
                && root.backlightDevices.indexOf(root.configuredBacklightDevice) !== -1)
            return root.configuredBacklightDevice;
        return root.backlightDevices.length > 0 ? root.backlightDevices[0] : "";
    }

    readonly property var battery: UPower.displayDevice
    readonly property bool supportsBattery: root.battery !== null
        && root.battery.ready
        && root.battery.isLaptopBattery
        && root.battery.isPresent
    readonly property bool supportsBrightness: root.backlightDevices.length > 0 && root.brightnessHelperAvailable
    readonly property bool supportsBluetooth: Bluetooth.defaultAdapter !== null
    readonly property bool supportsDisplayControl: root.hyprctlAvailable
    readonly property bool issuesReady: ConfigService.valid
        && root.backlightProbeComplete
        && root.toolProbeComplete
        && !PowerService.lockerChecking
    readonly property var issues: {
        if (!root.issuesReady)
            return [];
        var result = [];
        if (WeatherService.enabled && !root.curlAvailable) {
            result.push({
                id: "weather-curl",
                title: "Weather unavailable",
                detail: "Weather is enabled, but curl is not installed."
            });
        }
        var backlight = root.configuredBacklightDevice;
        if (backlight !== "" && root.backlightDevices.indexOf(backlight) === -1) {
            result.push({
                id: "backlight-device",
                title: "Backlight unavailable",
                detail: "The configured backlight device '" + backlight + "' was not found."
            });
        } else if (backlight !== "" && !root.brightnessHelperAvailable) {
            result.push({
                id: "backlight-helper",
                title: "Brightness controls unavailable",
                detail: "A backlight device is configured, but brightnessctl is not installed."
            });
        }
        var locker = String((PowerService.lockCommand || [])[0] || "");
        if (locker !== "" && !PowerService.lockerAvailable) {
            result.push({
                id: "power-locker",
                title: "Screen locking unavailable",
                detail: "The configured locker '" + locker + "' could not be found."
            });
        }
        return result;
    }

    Process {
        running: true
        command: ["ls", "-1", "/sys/class/backlight"]
        stdout: StdioCollector { id: backlightOutput }
        onExited: {
            root.backlightDevices = backlightOutput.text.split("\n")
                .map(function(line) { return line.trim(); })
                .filter(function(line) { return line !== ""; });
            root.backlightProbeComplete = true;
        }
    }

    // The optional helpers that are installed, one per line.
    Process {
        running: true
        command: ["sh", "-c", "for c; do command -v \"$c\" >/dev/null 2>&1 && echo \"$c\"; done", "sh",
            "brightnessctl", "hyprctl", "curl"]
        stdout: StdioCollector { id: toolOutput }
        onExited: {
            var installed = toolOutput.text.split("\n");
            root.brightnessHelperAvailable = installed.indexOf("brightnessctl") >= 0;
            root.hyprctlAvailable = installed.indexOf("hyprctl") >= 0;
            root.curlAvailable = installed.indexOf("curl") >= 0;
            root.toolProbeComplete = true;
        }
    }
}
