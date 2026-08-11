pragma ComponentBehavior: Bound
// qmllint disable unresolved-type

import QtQuick
import Quickshell.Bluetooth
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Bluetooth"
    iconName: "bluetooth"
    collapsible: true
    visible: Services.FeatureSupport.supportsBluetooth
    property bool presented: false

    // ── Native API helpers ──
    readonly property var adapter: Services.BluetoothService.adapter
    readonly property bool btOn: Services.BluetoothService.enabled
    readonly property bool scanning: Services.BluetoothService.scanning

    function buildConnectedDevices() {
        if (!root.adapter) return [];
        var result = [];
        for (var i = 0; i < root.adapter.devices.values.length; i++) {
            var dev = root.adapter.devices.values[i];
            if (dev.connected) result.push(dev);
        }
        return result;
    }

    function buildKnownDevices() {
        if (!root.adapter) return [];
        var result = [];
        for (var i = 0; i < root.adapter.devices.values.length; i++) {
            var dev = root.adapter.devices.values[i];
            if (dev.paired && !dev.connected) result.push(dev);
        }
        return result;
    }

    function buildDiscoveredDevices() {
        if (!root.adapter) return [];
        var result = [];
        for (var i = 0; i < root.adapter.devices.values.length; i++) {
            var dev = root.adapter.devices.values[i];
            if (!dev.paired && !dev.connected) result.push(dev);
        }
        return result;
    }

    readonly property var connectedDevices: root.buildConnectedDevices()
    readonly property var knownDevices: root.buildKnownDevices()
    readonly property var discoveredDevices: root.buildDiscoveredDevices()

    // Helper to build subtitle with connecting/disconnecting status
    function deviceSubtitle(dev) {
        if (dev.state === BluetoothDeviceState.Connecting) return "Connecting...";
        if (dev.state === BluetoothDeviceState.Disconnecting) return "Disconnecting...";
        if (dev.batteryAvailable) return "Battery " + dev.battery + "%";
        return "";
    }

    function deviceBadges(dev) {
        if (dev.state === BluetoothDeviceState.Connecting) return [{ text: "Connecting", tone: "info" }];
        if (dev.state === BluetoothDeviceState.Disconnecting) return [{ text: "Disconnecting", tone: "warning" }];
        if (dev.connected) return [{ text: "Connected", tone: "success" }];
        if (dev.paired) return [{ text: "Paired", tone: "neutral" }];
        return [{ text: "New", tone: "info" }];
    }

    function deviceActions(dev) {
        var busy = dev.state === BluetoothDeviceState.Connecting
            || dev.state === BluetoothDeviceState.Disconnecting;
        if (dev.connected) {
            return [{ text: "Disconnect", tone: "warning", enabled: !busy, actionId: "disconnect" }];
        }
        return [{ text: "Connect", tone: "success", enabled: !busy, actionId: "connect" }];
    }

    function deviceOpacity(dev) {
        var busy = dev.state === BluetoothDeviceState.Connecting
                || dev.state === BluetoothDeviceState.Disconnecting;
        if (busy) return 1.0;
        // Check if any device is busy
        if (root.adapter) {
            for (var i = 0; i < root.adapter.devices.values.length; i++) {
                var d = root.adapter.devices.values[i];
                if (d.state === BluetoothDeviceState.Connecting
                    || d.state === BluetoothDeviceState.Disconnecting) return 0.5;
            }
        }
        return 1.0;
    }

    headerActions: Row {
        spacing: ThemeModule.Theme.spacingSmall

        Components.RefreshButton {
            visible: root.btOn
            active: root.presented && root.scanning
            tooltipText: root.scanning ? "Stop Bluetooth scan" : "Scan for Bluetooth devices"
            onClicked: Services.BluetoothService.toggleDiscovery()
        }

        Components.ToggleSwitch {
            enabled: root.adapter !== null
            checked: root.btOn
            activeColor: ThemeModule.Theme.accent
            tooltipText: root.btOn ? "Turn Bluetooth off" : "Turn Bluetooth on"
            onToggled: function(state) {
                if (root.adapter)
                    root.adapter.enabled = state;
            }
        }
    }

    pinnedContent: [
        Components.DeviceSection {
            visible: root.btOn && root.connectedDevices.length > 0
            width: parent.width
            title: "Connected"
            count: root.connectedDevices.length
        },

        Repeater {
            model: root.btOn ? root.connectedDevices : []
            delegate: Components.DeviceRow {
                id: connectedDeviceRow
                required property var modelData
                width: parent.width
                title: connectedDeviceRow.modelData.name
                subtitle: root.deviceSubtitle(connectedDeviceRow.modelData)
                leadingIconName: "bluetooth"
                badges: root.deviceBadges(connectedDeviceRow.modelData)
                actionChips: root.deviceActions(connectedDeviceRow.modelData)
                primaryEnabled: false
                opacity: root.deviceOpacity(connectedDeviceRow.modelData)
                onActionTriggered: function(actionId) {
                    if (actionId === "disconnect") connectedDeviceRow.modelData.disconnect();
                    if (actionId === "connect") connectedDeviceRow.modelData.connect();
                }

                Behavior on opacity {
                    NumberAnimation { duration: ThemeModule.Theme.animDuration }
                }
            }
        },

        Text {
            visible: !root.btOn
            text: "Bluetooth is off"
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.overlay
            anchors.horizontalCenter: parent.horizontalCenter
        },

        Text {
            visible: root.btOn && root.connectedDevices.length === 0
            text: "No connected devices"
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.overlay
            anchors.horizontalCenter: parent.horizontalCenter
        }
    ]

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Components.DeviceSection {
            visible: root.btOn && root.knownDevices.length > 0
            width: parent.width
            title: "Known"
            count: root.knownDevices.length
        }

        Repeater {
            model: root.btOn ? root.knownDevices : []
            delegate: Components.DeviceRow {
                id: knownDeviceRow
                required property var modelData
                width: parent.width
                title: knownDeviceRow.modelData.name
                subtitle: root.deviceSubtitle(knownDeviceRow.modelData)
                leadingIconName: "bluetooth"
                badges: root.deviceBadges(knownDeviceRow.modelData)
                actionChips: root.deviceActions(knownDeviceRow.modelData)
                primaryEnabled: false
                opacity: root.deviceOpacity(knownDeviceRow.modelData)
                onActionTriggered: function(actionId) {
                    if (actionId === "connect") knownDeviceRow.modelData.connect();
                }

                Behavior on opacity {
                    NumberAnimation { duration: ThemeModule.Theme.animDuration }
                }
            }
        }

        Components.DeviceSection {
            visible: root.btOn && root.discoveredDevices.length > 0
            width: parent.width
            title: "Discovered"
            count: root.discoveredDevices.length
        }

        Repeater {
            model: root.btOn ? root.discoveredDevices : []
            delegate: Components.DeviceRow {
                id: discoveredDeviceRow
                required property var modelData
                width: parent.width
                title: discoveredDeviceRow.modelData.name
                subtitle: root.deviceSubtitle(discoveredDeviceRow.modelData)
                leadingIconName: "bluetooth"
                badges: root.deviceBadges(discoveredDeviceRow.modelData)
                actionChips: root.deviceActions(discoveredDeviceRow.modelData)
                primaryEnabled: false
                opacity: root.deviceOpacity(discoveredDeviceRow.modelData)
                onActionTriggered: function(actionId) {
                    if (actionId === "connect") discoveredDeviceRow.modelData.connect();
                }

                Behavior on opacity {
                    NumberAnimation { duration: ThemeModule.Theme.animDuration }
                }
            }
        }

        Text {
            visible: root.btOn && root.scanning && root.connectedDevices.length === 0 && root.knownDevices.length === 0 && root.discoveredDevices.length === 0
            text: "Scanning for devices..."
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.accent
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            visible: root.btOn && !root.scanning && root.connectedDevices.length === 0 && root.knownDevices.length === 0 && root.discoveredDevices.length === 0
            text: "No devices found. Run a scan."
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.overlay
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
