pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    property int scanDurationMs: 30000
    property int cacheMaxAgeMs: 10 * 60 * 1000
    property var cachedNetworks: []
    property int cacheUpdatedAtMs: 0
    property int nowMs: Date.now()
    property int networkListRevision: 0
    property bool nearbyExpanded: true

    // ── Native API helpers ──
    function findWifiDevice() {
        for (var i = 0; i < Networking.devices.values.length; i++) {
            var dev = Networking.devices.values[i];
            if (dev.type === DeviceType.Wifi) return dev;
        }
        return null;
    }

    function findWiredDevice() {
        for (var i = 0; i < Networking.devices.values.length; i++) {
            var dev = Networking.devices.values[i];
            if (dev.type === DeviceType.Wired && dev.connected) return dev;
        }
        return null;
    }

    function findConnectedWifi() {
        var dev = root.findWifiDevice();
        if (!dev) return null;
        for (var i = 0; i < dev.networks.values.length; i++) {
            var net = dev.networks.values[i];
            if (net.connected) return net;
        }
        return null;
    }

    function findConnectingNetwork() {
        var dev = root.findWifiDevice();
        if (!dev) return null;
        for (var i = 0; i < dev.networks.values.length; i++) {
            var net = dev.networks.values[i];
            if (net.state === ConnectionState.Connecting) return net;
        }
        return null;
    }

    function buildOtherNetworks() {
        var dev = root.findWifiDevice();
        if (!dev) return [];
        var result = [];
        for (var i = 0; i < dev.networks.values.length; i++) {
            var net = dev.networks.values[i];
            if (!net.connected && net.state !== ConnectionState.Connecting)
                result.push(net);
        }
        return result;
    }

    function networkKeyFromValues(name, security) {
        return String(name || "") + "|" + String(security);
    }

    function networkKey(network) {
        return root.networkKeyFromValues(network ? network.name : "", network ? network.security : "");
    }

    function signalPercent(value) {
        return Math.round((Number(value) || 0) * 100);
    }

    function signalIcon(level) {
        if (level > 75) return "wifi";
        if (level > 50) return "wifi-medium";
        if (level > 25) return "wifi-low";
        return "wifi-empty";
    }

    function networkSnapshot(network, now) {
        return {
            key: root.networkKey(network),
            name: network.name || "Hidden network",
            signalStrength: Number(network.signalStrength) || 0,
            signalLevel: root.signalPercent(network.signalStrength),
            security: network.security,
            known: !!network.known,
            stateChanging: !!network.stateChanging,
            network: network,
            live: true,
            lastSeenMs: now
        };
    }

    function findLiveNetwork(item) {
        if (!item || !root.wifiDevice) {
            return null;
        }

        for (var i = 0; i < root.wifiDevice.networks.values.length; i++) {
            var network = root.wifiDevice.networks.values[i];
            if (root.networkKey(network) === item.key) {
                return network;
            }
        }
        return null;
    }

    function sortNetworks(items) {
        items.sort(function(a, b) {
            if (!!a.known !== !!b.known) {
                return a.known ? -1 : 1;
            }
            if (a.signalLevel !== b.signalLevel) {
                return b.signalLevel - a.signalLevel;
            }
            return String(a.name).localeCompare(String(b.name));
        });
        return items;
    }

    function refreshNetworkCache() {
        var networks = root.otherNetworks;
        if (!networks || networks.length === 0) {
            return;
        }

        var now = root.nowMs;
        var byKey = {};
        var kept = [];

        for (var i = 0; i < root.cachedNetworks.length; i++) {
            var cached = root.cachedNetworks[i];
            if (cached && now - cached.lastSeenMs <= root.cacheMaxAgeMs) {
                byKey[cached.key] = cached;
            }
        }

        for (i = 0; i < networks.length; i++) {
            var snapshot = root.networkSnapshot(networks[i], now);
            byKey[snapshot.key] = snapshot;
        }

        for (var key in byKey) {
            kept.push(byKey[key]);
        }

        root.cachedNetworks = root.sortNetworks(kept);
        root.cacheUpdatedAtMs = now;
        root.nowMs = now;
    }

    function clearNetworkCache() {
        root.cachedNetworks = [];
        root.cacheUpdatedAtMs = 0;
    }

    function connectedNetworkKey() {
        return root.connectedWifi ? root.networkKey(root.connectedWifi) : "";
    }

    function buildDisplayedNetworks() {
        var result = [];
        var connectedKey = root.connectedNetworkKey();
        var now = root.nowMs;
        var revision = root.networkListRevision;

        for (var i = 0; i < root.cachedNetworks.length; i++) {
            var cached = root.cachedNetworks[i];
            if (!cached || cached.key === connectedKey || now - cached.lastSeenMs > root.cacheMaxAgeMs) {
                continue;
            }

            var liveNetwork = root.findLiveNetwork(cached);
            result.push({
                key: cached.key,
                name: cached.name,
                signalStrength: liveNetwork ? Number(liveNetwork.signalStrength) || 0 : cached.signalStrength,
                signalLevel: liveNetwork ? root.signalPercent(liveNetwork.signalStrength) : cached.signalLevel,
                security: liveNetwork ? liveNetwork.security : cached.security,
                known: liveNetwork ? !!liveNetwork.known : !!cached.known,
                stateChanging: liveNetwork ? !!liveNetwork.stateChanging : false,
                network: liveNetwork || null,
                live: liveNetwork !== null,
                lastSeenMs: cached.lastSeenMs
            });
        }

        return root.sortNetworks(result);
    }

    function cacheAgeText() {
        if (root.cacheUpdatedAtMs <= 0) {
            return "";
        }

        var elapsed = Math.max(0, root.nowMs - root.cacheUpdatedAtMs);
        if (elapsed < 15000) {
            return "just now";
        }
        if (elapsed < 60000) {
            return Math.floor(elapsed / 1000) + "s ago";
        }
        return Math.floor(elapsed / 60000) + "m ago";
    }

    function networkListStatusText() {
        if (root.isScanning) {
            return root.displayedNetworks.length > 0 ? "Refreshing nearby networks." : "Looking for nearby networks.";
        }
        if (root.cacheUpdatedAtMs > 0) {
            return "Last refreshed " + root.cacheAgeText() + ".";
        }
        return "";
    }

    function networkSubtitle(item) {
        if (!item) {
            return "";
        }
        if (item.stateChanging) {
            return "Connecting...";
        }
        return "";
    }

    function onNetworkItemPrimary(item) {
        var network = item ? root.findLiveNetwork(item) : null;
        if (!network) {
            root.startWifiScan();
            return;
        }
        root.onNetworkPrimary(network);
    }

    function requestConnectForItem(item, psk) {
        var network = item ? root.findLiveNetwork(item) : null;
        if (!network) {
            root.startWifiScan();
            return;
        }
        root.requestConnect(network, psk);
    }

    // ── Local state for password entry ──
    property string passwordRowName: ""
    property string passwordText: ""
    property string connectErrorName: ""
    property string connectError: ""
    property var pendingNetwork: null
    property string pendingNetworkName: ""

    function cancelPasswordPrompt() {
        root.passwordRowName = "";
        root.passwordText = "";
        root.connectErrorName = "";
        root.connectError = "";
    }

    function onNetworkPrimary(network) {
        if (network.connected) return;
        if (network.known || network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) {
            root.beginConnection(network, "");
            return;
        }

        if (!root.supportsPsk(network.security)) {
            root.connectErrorName = network.name;
            root.connectError = "This network needs settings that Speshell cannot request. Configure it in NetworkManager first.";
            return;
        }

        if (root.passwordRowName === network.name) {
            root.cancelPasswordPrompt();
        } else {
            root.passwordRowName = network.name;
            root.passwordText = "";
            root.connectErrorName = "";
            root.connectError = "";
        }
    }

    function supportsPsk(security) {
        return security === WifiSecurityType.WpaPsk
            || security === WifiSecurityType.Wpa2Psk
            || security === WifiSecurityType.Sae;
    }

    function beginConnection(network, psk) {
        root.stopWifiScan();
        root.pendingNetwork = network;
        root.pendingNetworkName = network.name || "Network";
        root.connectErrorName = "";
        root.connectError = "";
        if (psk !== "")
            network.connectWithPsk(psk);
        else
            network.connect();
        root.passwordText = "";
    }

    function requestConnect(network, psk) {
        var password = String(psk || "");
        if (!root.supportsPsk(network.security)) {
            root.connectErrorName = network.name;
            root.connectError = "Password entry is not supported for this network type.";
            return;
        }
        var minimumLength = network.security === WifiSecurityType.Sae ? 1 : 8;
        if (password.length < minimumLength) {
            root.connectErrorName = network.name;
            root.connectError = minimumLength === 1
                ? "Enter the network password."
                : "Enter a password with at least 8 characters.";
            return;
        }
        root.beginConnection(network, password);
    }

    function connectionFailureText(reason) {
        var reasonName = ConnectionFailReason.toString(reason);
        if (reason === ConnectionFailReason.NoSecrets)
            return "A password is required or the saved password was rejected.";
        if (reason === ConnectionFailReason.WifiAuthTimeout || reason === ConnectionFailReason.WifiClientFailed)
            return "Authentication failed. Check the password and try again.";
        if (reason === ConnectionFailReason.WifiNetworkLost)
            return "The network is no longer available. Refresh and try again.";
        return reasonName && reasonName !== "Unknown"
            ? "Connection failed: " + reasonName + "."
            : "Could not connect to the network.";
    }

    function handleConnectionFailed(reason) {
        root.connectErrorName = root.pendingNetworkName;
        root.connectError = root.connectionFailureText(reason);
        if (root.pendingNetwork && root.supportsPsk(root.pendingNetwork.security))
            root.passwordRowName = root.pendingNetworkName;
        root.pendingNetwork = null;
    }

    function startWifiScan() {
        if (!root.wifiDevice || !root.wifiOn)
            return;
        root.wifiDevice.scannerEnabled = true;
        wifiScanTimeoutTimer.restart();
    }

    function stopWifiScan() {
        if (root.wifiDevice)
            root.wifiDevice.scannerEnabled = false;
        wifiScanTimeoutTimer.stop();
    }

    function toggleWifiScan() {
        if (root.isScanning) {
            root.stopWifiScan();
        } else {
            root.startWifiScan();
        }
    }

    function wifiStatusText() {
        if (root.wiredDevice !== null && root.connectedWifi === null) {
            return "Ethernet connected.";
        }
        if (root.wifiDevice === null) {
            return "No Wi-Fi adapter found.";
        }
        if (!root.wifiOn) {
            return "Wi-Fi is off.";
        }
        if (root.connectedWifi !== null) {
            return "Connected to " + root.connectedWifi.name + ".";
        }
        if (root.connectingNetwork !== null) {
            return "Connecting to " + root.connectingNetwork.name + ".";
        }
        if (root.isScanning) {
            return "Refreshing nearby networks.";
        }
        if (root.displayedNetworks.length > 0) {
            return "Wi-Fi is ready.";
        }
        return "Refresh to find nearby networks.";
    }

    // ── Derived bindings ──
    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property var wifiDevice: root.findWifiDevice()
    readonly property var wiredDevice: root.findWiredDevice()
    readonly property var connectedWifi: root.findConnectedWifi()
    readonly property var connectingNetwork: root.findConnectingNetwork()
    readonly property var otherNetworks: root.buildOtherNetworks()
    readonly property var displayedNetworks: root.buildDisplayedNetworks()
    readonly property bool isScanning: root.wifiDevice ? root.wifiDevice.scannerEnabled : false

    onWifiOnChanged: {
        if (!root.wifiOn) {
            root.stopWifiScan();
            root.clearNetworkCache();
            root.pendingNetwork = null;
            root.cancelPasswordPrompt();
        }
    }

    onConnectedWifiChanged: {
        if (root.connectedWifi !== null && root.pendingNetwork !== null) {
            root.pendingNetwork = null;
            root.pendingNetworkName = "";
            root.cancelPasswordPrompt();
        }
    }

    Connections {
        target: root.pendingNetwork
        function onConnectionFailed(reason) {
            root.handleConnectionFailed(reason);
        }
    }

    onWifiDeviceChanged: {
        if (!root.wifiDevice) {
            wifiScanTimeoutTimer.stop();
            root.clearNetworkCache();
        }
    }

    onOtherNetworksChanged: {
        root.networkListRevision++;
        root.refreshNetworkCache();
    }

    onIsScanningChanged: {
        if (!root.isScanning)
            wifiScanTimeoutTimer.stop();
    }

    function setWifiEnabled(enabled) {
        Networking.wifiEnabled = !!enabled;
    }

    Component.onCompleted: root.refreshNetworkCache()
    Timer {
        id: wifiScanTimeoutTimer
        interval: root.scanDurationMs
        repeat: false
        onTriggered: root.stopWifiScan()
    }

    Timer {
        interval: 15000
        repeat: true
        running: root.cacheUpdatedAtMs > 0
        onTriggered: root.nowMs = Date.now()
    }
}
