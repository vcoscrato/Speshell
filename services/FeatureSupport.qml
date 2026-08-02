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

    Component.onCompleted: {
        backlightProbeProc.running = true;
        brightnessctlProc.running = true;
        hyprctlProc.running = true;
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
        }
    }

    Process {
        id: brightnessctlProc
        command: ["which", "brightnessctl"]
        running: false
        onExited: function(exitCode) {
            root.brightnessHelperAvailable = exitCode === 0;
        }
    }

    Process {
        id: hyprctlProc
        command: ["which", "hyprctl"]
        running: false
        onExited: function(exitCode) {
            root.hyprctlAvailable = exitCode === 0;
        }
    }
}
