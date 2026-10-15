pragma ComponentBehavior: Bound
import QtQuick
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root

    property bool presented: false
    // "output" = speaker, "input" = mic, "combined" = both speaker & mic in one card
    property string mode: "output"

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingXL

        // ── OUTPUT CONTROL SECTION ────────────────────────
        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: root.mode === "output" || root.mode === "combined"

            Row {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Components.IconButton {
                    iconName: Services.AudioService.outputMuted ? "audio-output-muted" : "audio-output"
                    anchors.verticalCenter: parent.verticalCenter
                    tooltipText: Services.AudioService.outputMuted ? "Unmute output" : "Mute output"
                    onClicked: Services.AudioService.toggleOutputMute()
                }

                Components.StyledSlider {
                    width: parent.width - 88
                    anchors.verticalCenter: parent.verticalCenter
                    value: Services.AudioService.hasOutputVolume ? Services.AudioService.outputVolumePercent : 0
                    enabled: Services.AudioService.defaultSink && Services.AudioService.hasOutputVolume
                    stepSize: Services.AudioService.scrollStep
                    onMoved: {
                        Services.AudioService.setOutputVolumePercent(Math.round(value));
                    }
                    onWheelAdjusted: function(nextValue) {
                        Services.AudioService.setOutputVolumePercent(Math.round(nextValue));
                    }
                }

                Text {
                    text: !Services.AudioService.defaultSink ? "—" : (Services.AudioService.hasOutputVolume ? Services.AudioService.outputVolumePercent + "%" : "…")
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.subtext
                    width: 40
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Output Devices List
            Column {
                width: parent.width
                spacing: ThemeModule.Theme.spacingTiny

                Repeater {
                    model: root.presented ? Services.AudioService.devices(true) : []

                    delegate: Rectangle {
                        id: outDevDelegate
                        required property var modelData
                        readonly property bool selected: Services.AudioService.defaultSink === outDevDelegate.modelData.node
                        width: parent.width
                        height: ThemeModule.Theme.controlHeight
                        radius: ThemeModule.Theme.borderRadiusSmall
                        color: outDevDelegate.selected
                            ? ThemeModule.Theme.selectedFill
                            : (outDevMouse.containsMouse ? ThemeModule.Theme.controlFill : "transparent")
                        border.width: ThemeModule.Theme.borderWidth
                        border.color: outDevDelegate.selected ? ThemeModule.Theme.selectedBorder : "transparent"

                        Accessible.role: Accessible.Button
                        Accessible.name: "Use " + outDevDelegate.modelData.label + " for audio output"
                        Accessible.onPressAction: Services.AudioService.setDefaultSink(outDevDelegate.modelData.node)
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: ThemeModule.Theme.spacingSmall
                            spacing: ThemeModule.Theme.spacingSmall

                            Rectangle {
                                id: outDevDot
                                width: 14; height: 14; radius: 7
                                anchors.verticalCenter: parent.verticalCenter
                                border.width: 2
                                border.color: ThemeModule.Theme.accent
                                color: outDevDelegate.selected ? ThemeModule.Theme.accent : "transparent"
                            }

                            Text {
                                text: outDevDelegate.modelData.label
                                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                                font.family: ThemeModule.Theme.fontFamily
                                font.weight: outDevDelegate.selected ? Font.DemiBold : Font.Normal
                                color: ThemeModule.Theme.text
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // A renamed device shows its hardware name on hover.
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: ThemeModule.Theme.spacingSmall
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, parent.width * 0.5)
                            visible: outDevDelegate.modelData.label !== outDevDelegate.modelData.rawLabel
                            opacity: outDevMouse.containsMouse ? 1 : 0
                            text: outDevDelegate.modelData.rawLabel
                            font.pixelSize: ThemeModule.Theme.fontSizeCaption
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.overlay
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: outDevMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                if (Services.AudioService.defaultSink !== outDevDelegate.modelData.node)
                                    Services.EffectsService.picked(outDevDot, outDevMouse);
                                Services.AudioService.setDefaultSink(outDevDelegate.modelData.node);
                            }
                        }
                    }
                }
            }
        }

        // ── INPUT / MICROPHONE CONTROL SECTION ────────────────────────
        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: root.mode === "input" || root.mode === "combined"

            Row {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Components.IconButton {
                    iconName: Services.AudioService.inputMuted ? "audio-input-muted" : "audio-input"
                    anchors.verticalCenter: parent.verticalCenter
                    tooltipText: Services.AudioService.inputMuted ? "Unmute input" : "Mute input"
                    onClicked: Services.AudioService.toggleInputMute()
                }

                Components.StyledSlider {
                    width: parent.width - 88
                    anchors.verticalCenter: parent.verticalCenter
                    value: Services.AudioService.hasInputVolume ? Services.AudioService.inputVolumePercent : 0
                    enabled: Services.AudioService.defaultSource && Services.AudioService.hasInputVolume
                    stepSize: Services.AudioService.scrollStep
                    onMoved: {
                        Services.AudioService.setInputVolumePercent(Math.round(value));
                    }
                    onWheelAdjusted: function(nextValue) {
                        Services.AudioService.setInputVolumePercent(Math.round(nextValue));
                    }
                }

                Text {
                    text: !Services.AudioService.defaultSource ? "—" : (Services.AudioService.hasInputVolume ? Services.AudioService.inputVolumePercent + "%" : "…")
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.subtext
                    width: 40
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            // Input Devices List
            Column {
                width: parent.width
                spacing: ThemeModule.Theme.spacingTiny

                Repeater {
                    model: root.presented ? Services.AudioService.devices(false) : []

                    delegate: Rectangle {
                        id: inDevDelegate
                        required property var modelData
                        readonly property bool selected: Services.AudioService.defaultSource === inDevDelegate.modelData.node
                        width: parent.width
                        height: ThemeModule.Theme.controlHeight
                        radius: ThemeModule.Theme.borderRadiusSmall
                        color: inDevDelegate.selected
                            ? ThemeModule.Theme.selectedFill
                            : (inDevMouse.containsMouse ? ThemeModule.Theme.controlFill : "transparent")
                        border.width: ThemeModule.Theme.borderWidth
                        border.color: inDevDelegate.selected ? ThemeModule.Theme.selectedBorder : "transparent"

                        Accessible.role: Accessible.Button
                        Accessible.name: "Use " + inDevDelegate.modelData.label + " for audio input"
                        Accessible.onPressAction: Services.AudioService.setDefaultSource(inDevDelegate.modelData.node)
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: ThemeModule.Theme.spacingSmall
                            spacing: ThemeModule.Theme.spacingSmall

                            Rectangle {
                                id: inDevDot
                                width: 14; height: 14; radius: 7
                                anchors.verticalCenter: parent.verticalCenter
                                border.width: 2
                                border.color: ThemeModule.Theme.accent
                                color: inDevDelegate.selected ? ThemeModule.Theme.accent : "transparent"
                            }

                            Text {
                                text: inDevDelegate.modelData.label
                                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                                font.family: ThemeModule.Theme.fontFamily
                                font.weight: inDevDelegate.selected ? Font.DemiBold : Font.Normal
                                color: ThemeModule.Theme.text
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // A renamed device shows its hardware name on hover.
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: ThemeModule.Theme.spacingSmall
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, parent.width * 0.5)
                            visible: inDevDelegate.modelData.label !== inDevDelegate.modelData.rawLabel
                            opacity: inDevMouse.containsMouse ? 1 : 0
                            text: inDevDelegate.modelData.rawLabel
                            font.pixelSize: ThemeModule.Theme.fontSizeCaption
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.overlay
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: inDevMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                if (Services.AudioService.defaultSource !== inDevDelegate.modelData.node)
                                    Services.EffectsService.picked(inDevDot, inDevMouse);
                                Services.AudioService.setDefaultSource(inDevDelegate.modelData.node);
                            }
                        }
                    }
                }
            }
        }
    }
}
