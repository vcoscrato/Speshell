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


    pinnedContent: [
        // Ethernet Section
        Components.DeviceRow {
            visible: root.network.wiredDevice !== null
            width: parent.width
            title: root.network.wiredDevice ? root.network.wiredDevice.name : "Ethernet"
            subtitle: "Connected"
            leadingIconName: "plug"
            primaryEnabled: false
        },

        // Wi-Fi Header / Controls
        Item {
            width: parent.width
            height: 36

            Text {
                id: wifiLabel
                text: "Wi-Fi"
                font.pixelSize: ThemeModule.Theme.fontSizeNormal
                font.family: ThemeModule.Theme.fontFamily
                font.bold: true
                color: ThemeModule.Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                id: wifiControls
                spacing: ThemeModule.Theme.spacingSmall
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right

                Components.RefreshButton {
                    visible: root.network.wifiOn && root.network.wifiDevice !== null
                    active: root.presented && root.network.isScanning
                    tooltipText: root.network.isScanning ? "Stop Wi-Fi scan" : "Refresh Wi-Fi networks"
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
        },

        Text {
            visible: root.network.connectedWifi === null || root.network.connectingNetwork !== null
            width: parent.width
            text: root.network.wifiStatusText()
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: root.network.wifiDevice === null || !root.network.wifiOn
                ? ThemeModule.Theme.overlay
                : ThemeModule.Theme.subtext
            wrapMode: Text.WordWrap
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

        Item {
            visible: root.network.connectedWifi !== null
            width: parent.width
            height: visible ? 44 : 0

            Rectangle {
                anchors.fill: parent
                radius: ThemeModule.Theme.borderRadiusSmall
                color: connectedDisconnectMouse.containsMouse
                    ? Qt.rgba(ThemeModule.Theme.error.r, ThemeModule.Theme.error.g, ThemeModule.Theme.error.b, 0.07)
                    : "transparent"
            }

            Row {
                anchors.left: parent.left
                anchors.right: connectedDisconnectText.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: ThemeModule.Theme.spacingMedium
                spacing: ThemeModule.Theme.spacingSmall

                Components.AppIcon {
                    id: connectedSignalText
                    name: root.network.signalIcon(root.network.signalPercent(root.network.connectedWifi ? root.network.connectedWifi.signalStrength : 0))
                    size: 18
                    iconColor: ThemeModule.Theme.success
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    width: parent.width - connectedSignalText.width - ThemeModule.Theme.spacingSmall
                    spacing: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        width: parent.width
                        text: root.network.connectedWifi ? root.network.connectedWifi.name : ""
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        font.bold: true
                        color: ThemeModule.Theme.text
                        elide: Text.ElideRight
                    }

                    Row {
                        spacing: ThemeModule.Theme.spacingTiny

                        Text {
                            text: "Connected"
                            font.pixelSize: 10
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.success
                        }

                        Components.AppIcon {
                            name: "lock"
                            size: 11
                            iconColor: ThemeModule.Theme.subtext
                            visible: root.network.connectedWifi && root.network.connectedWifi.security !== WifiSecurityType.Open
                        }
                    }
                }
            }

            Text {
                id: connectedDisconnectText
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Disconnect"
                font.pixelSize: 10
                font.family: ThemeModule.Theme.fontFamily
                font.bold: true
                color: connectedDisconnectMouse.containsMouse ? ThemeModule.Theme.error : ThemeModule.Theme.subtext
            }

            MouseArea {
                id: connectedDisconnectMouse
                anchors.fill: connectedDisconnectText
                anchors.margins: -ThemeModule.Theme.spacingSmall
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.network.connectedWifi) root.network.connectedWifi.disconnect();
                }
            }
        },

        // ── Connecting indicator ──
        Item {
            visible: root.network.connectingNetwork !== null && root.network.connectedWifi === null
            width: parent.width
            height: 36

            Row {
                anchors.centerIn: parent
                spacing: ThemeModule.Theme.spacingSmall

                Components.AppIcon {
                    name: "loader"
                    size: 17
                    iconColor: ThemeModule.Theme.accent
                    anchors.verticalCenter: parent.verticalCenter

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 1200
                        loops: Animation.Infinite
                        running: root.presented && root.network.connectingNetwork !== null
                    }
                }

                Text {
                    text: "Connecting to " + (root.network.connectingNetwork ? root.network.connectingNetwork.name : "") + "..."
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    ]

    content: [
        Column {
            visible: root.network.wifiOn && root.network.wifiDevice !== null
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall

            Item {
                visible: root.network.displayedNetworks.length > 0 || root.network.cacheUpdatedAtMs > 0 || root.network.isScanning
                width: parent.width
                height: 26

                MouseArea {
                    anchors.fill: parent
                    enabled: root.network.displayedNetworks.length > 0
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.network.nearbyExpanded = !root.network.nearbyExpanded
                }

                Row {
                    spacing: ThemeModule.Theme.spacingSmall
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "Nearby"
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        font.bold: true
                        color: ThemeModule.Theme.subtext
                    }

                    Text {
                        text: root.network.displayedNetworks.length
                        font.pixelSize: 10
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.overlay
                    }
                }

                Components.AppIcon {
                    visible: root.network.displayedNetworks.length > 0
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.network.nearbyExpanded ? "chevron-down" : "chevron-right"
                    size: 14
                    iconColor: ThemeModule.Theme.subtext
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.14)
                }
            }

            Repeater {
                model: root.network.nearbyExpanded ? root.network.displayedNetworks : []
                delegate: Column {
                    id: nearbyNetworkDelegate
                    required property var modelData

                    width: parent.width
                    spacing: ThemeModule.Theme.spacingSmall
                    opacity: modelData.live && !modelData.stateChanging ? 1.0 : 0.55

                    Item {
                        id: nearbyNetworkRow
                        width: parent.width
                        height: 34

                        Rectangle {
                            anchors.fill: parent
                            radius: ThemeModule.Theme.borderRadiusSmall
                            color: nearbyRowMouse.containsMouse && nearbyRowMouse.enabled
                                ? ThemeModule.Theme.cardHover
                                : "transparent"
                        }

                        MouseArea {
                            id: nearbyRowMouse
                            anchors.fill: parent
                            enabled: nearbyNetworkDelegate.modelData.live && !nearbyNetworkDelegate.modelData.stateChanging
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.network.onNetworkItemPrimary(nearbyNetworkDelegate.modelData)
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.right: nearbyActionArea.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: ThemeModule.Theme.spacingSmall
                            spacing: ThemeModule.Theme.spacingSmall

                            Components.AppIcon {
                                id: nearbySignalText
                                name: root.network.signalIcon(nearbyNetworkDelegate.modelData.signalLevel)
                                size: 18
                                iconColor: ThemeModule.Theme.success
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                width: parent.width - nearbySignalText.width - ThemeModule.Theme.spacingSmall
                                text: nearbyNetworkDelegate.modelData.name
                                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                                font.family: ThemeModule.Theme.fontFamily
                                font.bold: true
                                color: ThemeModule.Theme.text
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            id: nearbyActionArea
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: ThemeModule.Theme.spacingSmall

                            Components.AppIcon {
                                visible: nearbyNetworkDelegate.modelData.security !== WifiSecurityType.Open
                                name: "lock"
                                size: 11
                                iconColor: ThemeModule.Theme.subtext
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                id: forgetText
                                visible: nearbyNetworkDelegate.modelData.live
                                    && nearbyNetworkDelegate.modelData.known
                                    && nearbyNetworkDelegate.modelData.network
                                    && nearbyRowMouse.containsMouse
                                text: "Forget"
                                font.pixelSize: 10
                                font.family: ThemeModule.Theme.fontFamily
                                font.bold: true
                                color: forgetMouse.containsMouse ? ThemeModule.Theme.warning : ThemeModule.Theme.subtext
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    id: forgetMouse
                                    anchors.fill: parent
                                    anchors.margins: -ThemeModule.Theme.spacingSmall
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (nearbyNetworkDelegate.modelData.network)
                                            nearbyNetworkDelegate.modelData.network.forget();
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: root.network.passwordRowName === nearbyNetworkDelegate.modelData.name
                        width: parent.width
                        height: 32
                        radius: ThemeModule.Theme.borderRadiusSmall
                        color: ThemeModule.Theme.card
                        border.width: ThemeModule.Theme.borderWidth
                        border.color: Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.5)

                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            anchors.margins: ThemeModule.Theme.spacingSmall
                            text: root.network.passwordText
                            echoMode: TextInput.Password
                            color: ThemeModule.Theme.text
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            onTextChanged: root.network.passwordText = text
                            onAccepted: root.network.requestConnectForItem(nearbyNetworkDelegate.modelData, root.network.passwordText)
                            Keys.onReturnPressed: root.network.requestConnectForItem(nearbyNetworkDelegate.modelData, root.network.passwordText)
                            Keys.onEnterPressed: root.network.requestConnectForItem(nearbyNetworkDelegate.modelData, root.network.passwordText)

                            Component.onCompleted: {
                                if (root.network.passwordRowName === nearbyNetworkDelegate.modelData.name)
                                    passwordInput.forceActiveFocus();
                            }
                        }

                        onVisibleChanged: {
                            if (visible)
                                passwordInput.forceActiveFocus();
                        }
                    }

                    Row {
                        visible: root.network.passwordRowName === nearbyNetworkDelegate.modelData.name
                        spacing: ThemeModule.Theme.spacingSmall

                        Components.InlineActionChip {
                            text: "Connect"
                            tone: "success"
                            onActivated: root.network.requestConnectForItem(nearbyNetworkDelegate.modelData, root.network.passwordText)
                        }

                        Components.InlineActionChip {
                            text: "Cancel"
                            tone: "neutral"
                            onActivated: root.network.cancelPasswordPrompt()
                        }
                    }

                    Text {
                        visible: root.network.passwordRowName === nearbyNetworkDelegate.modelData.name
                            && root.network.connectErrorName === nearbyNetworkDelegate.modelData.name
                        text: root.network.connectError
                        font.pixelSize: 10
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.error
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: ThemeModule.Theme.animDuration }
                    }
                }
            }

            Text {
                visible: root.network.wifiOn && root.network.wifiDevice !== null && root.network.networkListStatusText() !== ""
                text: root.network.networkListStatusText()
                font.pixelSize: 10
                font.family: ThemeModule.Theme.fontFamily
                color: root.network.isScanning ? ThemeModule.Theme.accent : ThemeModule.Theme.overlay
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                visible: root.network.nearbyExpanded && root.network.displayedNetworks.length === 0 && root.network.wifiOn && !root.network.isScanning
                text: root.network.cacheUpdatedAtMs > 0 ? "No nearby networks from the last refresh" : "Refresh to scan for networks"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.overlay
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                visible: root.network.nearbyExpanded && root.network.displayedNetworks.length === 0 && root.network.wifiOn && root.network.isScanning
                text: "Looking for nearby networks..."
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.accent
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    ]
}
