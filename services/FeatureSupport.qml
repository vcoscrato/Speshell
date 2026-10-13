pragma Singleton
// qmllint disable signal-handler-parameters unresolved-type

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.UPower

Singleton {
    id: root

    property bool hasBacklightDevice: false
    property bool brightnessHelperAvailable: false
    property bool hyprctlAvailable: false
    property bool curlAvailable: false
    property bool backlightProbeComplete: false
    property bool brightnessProbeComplete: false
    property bool hyprctlProbeComplete: false
    property bool curlProbeComplete: false
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
    readonly property bool supportsBrightness: root.hasBacklightDevice && root.brightnessHelperAvailable
    readonly property bool supportsHyprland: root.hyprctlAvailable
    readonly property bool supportsBluetooth: Bluetooth.defaultAdapter !== null
    readonly property bool supportsDisplayControl: root.supportsHyprland
    readonly property bool probesComplete: root.backlightProbeComplete
        && root.brightnessProbeComplete
        && root.hyprctlProbeComplete
        && root.curlProbeComplete
    readonly property bool issuesReady: ConfigService.valid
        && root.probesComplete
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

    Component.onCompleted: {
        backlightProbeProc.running = true;
        brightnessctlProc.running = true;
        hyprctlProc.running = true;
        curlProc.running = true;
    }

    Process {
        id: backlightProbeProc
        command: ["ls", "-1", "/sys/class/backlight"]
        running: false
        property var detectedDevices: []
        onRunningChanged: if (running) detectedDevices = []
        stdout: SplitParser {
            onRead: function(line) {
                var trimmed = (line || "").trim();
                if (trimmed !== "")
                    backlightProbeProc.detectedDevices.push(trimmed);
            }
        }
        onExited: {
            root.backlightDevices = backlightProbeProc.detectedDevices.slice();
            root.hasBacklightDevice = root.backlightDevices.length > 0;
            root.backlightProbeComplete = true;
        }
    }

    Process {
        id: brightnessctlProc
        command: ["which", "brightnessctl"]
        running: false
        onExited: function(exitCode) {
            root.brightnessHelperAvailable = exitCode === 0;
            root.brightnessProbeComplete = true;
        }
    }

    Process {
        id: hyprctlProc
        command: ["which", "hyprctl"]
        running: false
        onExited: function(exitCode) {
            root.hyprctlAvailable = exitCode === 0;
            root.hyprctlProbeComplete = true;
        }
    }

    Process {
        id: curlProc
        command: ["which", "curl"]
        running: false
        onExited: function(exitCode) {
            root.curlAvailable = exitCode === 0;
            root.curlProbeComplete = true;
        }
    }
}
