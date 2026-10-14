pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Networking
import "../components" as Components
import "../theme" as ThemeModule
import "../services" as Services

Components.Card {
    id: root
    title: "Network"
    iconName: "wifi"
    collapsible: true
    property bool presented: false
    readonly property var network: Services.NetworkService
    readonly property bool wifiReady: root.network.wifiOn && root.network.wifiDevice !== null
    readonly property bool connecting: root.network.connectingNetwork !== null && root.network.connectedWifi === null

    // Scanning waits for the refresh button; closing the panel stops it.
    onPresentedChanged: if (!root.presented && root.network.isScanning) root.network.stopWifiScan()
    Component.onDestruction: if (root.network.isScanning) root.network.stopWifiScan()

    headerActions: Row {
        spacing: ThemeModule.Theme.spacingSmall

        Components.RefreshButton {
            visible: root.wifiReady
            active: root.presented && root.network.isScanning
            tooltipText: root.network.isScanning ? "Stop Wi-Fi scan" : "Scan for Wi-Fi networks"
            onClicked: root.network.toggleWifiScan()
        }

        Components.ToggleSwitch {
            visible: root.network.wifiDevice !== null
            checked: root.network.wifiOn
            activeColor: ThemeModule.Theme.accent
            tooltipText: root.network.wifiOn ? "Turn Wi-Fi off" : "Turn Wi-Fi on"
            onToggled: function(state) {
                Networking.wifiEnabled = state;
            }
        }
    }

    pinnedContent: [
        Components.DeviceRow {
            visible: root.network.wiredDevice !== null
            title: root.network.wiredDevice ? root.network.wiredDevice.name : "Ethernet"
            subtitle: "Wired · Connected"
            iconName: "network-wired"
            current: true
            primaryEnabled: false
        },

        Components.DeviceRow {
            visible: root.network.connectedWifi !== null
            title: root.network.connectedWifi ? root.network.connectedWifi.name : ""
            subtitle: root.network.connectedSubtitle()
            iconName: root.network.signalIcon(root.network.signalPercent(
                root.network.connectedWifi ? root.network.connectedWifi.signalStrength : 0))
            current: true
            primaryEnabled: false
            actionChips: [{ text: "Disconnect", tone: "neutral", actionId: "disconnect" }]
            onActionTriggered: {
                if (root.network.connectedWifi)
                    root.network.connectedWifi.disconnect();
            }
        },

        Components.DeviceRow {
            visible: root.connecting
            title: root.network.connectingNetwork ? root.network.connectingNetwork.name : ""
            subtitle: "Connecting…"
            subtitleColor: ThemeModule.Theme.accent
            busy: true
            primaryEnabled: false
        },

        Text {
            visible: root.network.connectError !== "" && root.network.passwordRowName === ""
            width: parent.width
            text: root.network.connectError
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.error
            wrapMode: Text.WordWrap
        },

        Components.EmptyState {
            visible: root.network.wifiDevice === null && root.network.wiredDevice === null
            iconName: "wifi-off"
            title: "No network adapter"
            detail: "No Wi-Fi or wired network device was found."
        },

        Components.EmptyState {
            visible: root.network.wifiDevice !== null && !root.network.wifiOn
            iconName: "wifi-off"
            title: "Wi-Fi is off"
            detail: "Turn it on to see networks nearby."
            actionLabel: "Turn on Wi-Fi"
            actionIconName: "wifi"
            onActivated: Networking.wifiEnabled = true
        }
    ]

    content: [
        Column {
            visible: root.wifiReady
            width: parent.width
            spacing: ThemeModule.Theme.spacingTiny

            Components.DeviceSection {
                title: "Nearby"
                count: root.network.displayedNetworks.length
                status: root.network.nearbyStatusText()
                statusActive: root.network.isScanning
            }

            Item { width: 1; height: ThemeModule.Theme.spacingTiny }

            Repeater {
                model: root.network.displayedNetworks
                delegate: Components.DeviceRow {
                    id: networkRow
                    required property var modelData
                    readonly property bool prompting: root.network.passwordRowName === networkRow.modelData.name

                    title: networkRow.modelData.name
                    subtitle: root.network.networkSubtitle(networkRow.modelData)
                    iconName: root.network.signalIcon(networkRow.modelData.signalLevel)
                    busy: networkRow.modelData.stateChanging
                    primaryEnabled: networkRow.modelData.live && !networkRow.modelData.stateChanging
                    opacity: networkRow.modelData.live ? 1.0 : ThemeModule.Theme.disabledOpacity
                    actionChips: networkRow.modelData.live && networkRow.modelData.known && networkRow.modelData.network
                        ? [{ text: "Forget", tone: "warning", actionId: "forget" }]
                        : []
                    onPrimaryTriggered: root.network.onNetworkItemPrimary(networkRow.modelData)
                    onActionTriggered: {
                        if (networkRow.modelData.network)
                            networkRow.modelData.network.forget();
                    }

                    Rectangle {
                        visible: networkRow.prompting
                        width: parent.width
                        height: ThemeModule.Theme.controlHeight
                        radius: ThemeModule.Theme.borderRadiusSmall
                        color: ThemeModule.Theme.card
                        border.width: ThemeModule.Theme.borderWidth
                        border.color: passwordInput.activeFocus ? ThemeModule.Theme.accent : ThemeModule.Theme.cardHover

                        TextInput {
                            id: passwordInput
                            anchors.left: parent.left
                            anchors.right: promptActions.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: ThemeModule.Theme.spacingSmall
                            anchors.rightMargin: ThemeModule.Theme.spacingSmall
                            text: root.network.passwordText
                            echoMode: TextInput.Password
                            color: ThemeModule.Theme.text
                            selectionColor: ThemeModule.Theme.accent
                            selectedTextColor: ThemeModule.Theme.bg
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            clip: true
                            onTextChanged: root.network.passwordText = text
                            onAccepted: root.network.requestConnectForItem(networkRow.modelData, root.network.passwordText)
                            Keys.onEscapePressed: root.network.cancelPasswordPrompt()

                            Component.onCompleted: {
                                if (networkRow.prompting)
                                    passwordInput.forceActiveFocus();
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Password"
                                color: ThemeModule.Theme.overlay
                                font: passwordInput.font
                                visible: passwordInput.text === ""
                            }
                        }

                        Row {
                            id: promptActions
                            anchors.right: parent.right
                            anchors.rightMargin: ThemeModule.Theme.spacingTiny
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: ThemeModule.Theme.spacingTiny

                            Components.InlineActionChip {
                                text: "Connect"
                                tone: "success"
                                onActivated: root.network.requestConnectForItem(networkRow.modelData, root.network.passwordText)
                            }

                            Components.InlineActionChip {
                                text: "Cancel"
                                onActivated: root.network.cancelPasswordPrompt()
                            }
                        }

                        onVisibleChanged: {
                            if (visible)
                                passwordInput.forceActiveFocus();
                        }
                    }

                    Text {
                        visible: networkRow.prompting && root.network.connectErrorName === networkRow.modelData.name
                        width: parent.width
                        text: root.network.connectError
                        font.pixelSize: ThemeModule.Theme.fontSizeCaption
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.error
                        wrapMode: Text.WordWrap
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: ThemeModule.Theme.animDuration }
                    }
                }
            }

            Components.EmptyState {
                visible: root.network.displayedNetworks.length === 0
                iconName: "wifi"
                busy: root.network.isScanning
                title: root.network.isScanning ? "Looking for networks…"
                    : (root.network.scanRequested ? "No other networks found" : "No scan yet")
                detail: root.network.isScanning ? ""
                    : (root.network.scanRequested ? "Nothing else is in range right now." : "Scan to see the Wi-Fi networks around you.")
                actionLabel: root.network.isScanning ? "" : (root.network.scanRequested ? "Scan again" : "Scan")
                actionIconName: "refresh"
                onActivated: root.network.startWifiScan()
            }
        }
    ]
}
