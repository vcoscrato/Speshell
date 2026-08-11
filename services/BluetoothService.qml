pragma Singleton
// qmllint disable unresolved-type

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    property int scanDurationMs: 20000
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: root.adapter ? root.adapter.enabled : false
    readonly property bool scanning: root.adapter ? root.adapter.discovering : false

    function startDiscovery() {
        if (!root.adapter || !root.enabled)
            return;

        root.adapter.discovering = true;
        discoveryTimeout.restart();
    }

    function stopDiscovery() {
        if (root.adapter)
            root.adapter.discovering = false;
        discoveryTimeout.stop();
    }

    function toggleDiscovery() {
        if (root.scanning)
            root.stopDiscovery();
        else
            root.startDiscovery();
    }

    onEnabledChanged: {
        if (!root.enabled)
            root.stopDiscovery();
    }

    onAdapterChanged: {
        if (!root.adapter)
            discoveryTimeout.stop();
    }

    onScanningChanged: {
        if (!root.scanning)
            discoveryTimeout.stop();
    }

    Timer {
        id: discoveryTimeout
        interval: root.scanDurationMs
        repeat: false
        onTriggered: root.stopDiscovery()
    }
}
