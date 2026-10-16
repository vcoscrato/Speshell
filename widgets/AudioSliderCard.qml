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

    // One direction's mute button, volume slider, and device list.
    component Section: Column {
        id: section

        property bool output: true
        property bool presented: false
        readonly property string kind: section.output ? "output" : "input"
        readonly property var device: section.output ? Services.AudioService.defaultSink : Services.AudioService.defaultSource
        readonly property bool muted: section.output ? Services.AudioService.outputMuted : Services.AudioService.inputMuted
        readonly property bool hasVolume: section.output ? Services.AudioService.hasOutputVolume : Services.AudioService.hasInputVolume
        readonly property int volumePercent: section.output
            ? Services.AudioService.outputVolumePercent
            : Services.AudioService.inputVolumePercent

        function setVolume(percent) {
            if (section.output)
                Services.AudioService.setOutputVolumePercent(Math.round(percent));
            else
                Services.AudioService.setInputVolumePercent(Math.round(percent));
        }

        function setDevice(node) {
            if (section.output)
                Services.AudioService.setDefaultSink(node);
            else
                Services.AudioService.setDefaultSource(node);
        }

        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Row {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall

            Components.IconButton {
                iconName: section.output
                    ? (section.muted ? "audio-output-muted" : "audio-output")
                    : (section.muted ? "audio-input-muted" : "audio-input")
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: (section.muted ? "Unmute " : "Mute ") + section.kind
                onClicked: {
                    if (section.output)
                        Services.AudioService.toggleOutputMute();
                    else
                        Services.AudioService.toggleInputMute();
                }
            }

            Components.StyledSlider {
                width: parent.width - 88
                anchors.verticalCenter: parent.verticalCenter
                value: section.hasVolume ? section.volumePercent : 0
                enabled: section.device && section.hasVolume
                stepSize: Services.AudioService.scrollStep
                onMoved: section.setVolume(value)
                onWheelAdjusted: function(nextValue) { section.setVolume(nextValue); }
            }

            Text {
                text: !section.device ? "—" : (section.hasVolume ? section.volumePercent + "%" : "…")
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext
                width: 40
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingTiny

            Repeater {
                model: section.presented ? Services.AudioService.devices(section.output) : []

                delegate: Rectangle {
                    id: devDelegate
                    required property var modelData
                    readonly property bool selected: section.device === devDelegate.modelData.node
                    width: parent.width
                    height: ThemeModule.Theme.controlHeight
                    radius: ThemeModule.Theme.borderRadiusSmall
                    color: devDelegate.selected
                        ? ThemeModule.Theme.selectedFill
                        : (devMouse.containsMouse ? ThemeModule.Theme.controlFill : "transparent")
                    border.width: ThemeModule.Theme.borderWidth
                    border.color: devDelegate.selected ? ThemeModule.Theme.selectedBorder : "transparent"

                    Accessible.role: Accessible.Button
                    Accessible.name: "Use " + devDelegate.modelData.label + " for audio " + section.kind
                    Accessible.onPressAction: section.setDevice(devDelegate.modelData.node)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: ThemeModule.Theme.spacingSmall
                        spacing: ThemeModule.Theme.spacingSmall

                        Rectangle {
                            id: devDot
                            width: 14; height: 14; radius: 7
                            anchors.verticalCenter: parent.verticalCenter
                            border.width: 2
                            border.color: ThemeModule.Theme.accent
                            color: devDelegate.selected ? ThemeModule.Theme.accent : "transparent"
                        }

                        Text {
                            text: devDelegate.modelData.label
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            font.weight: devDelegate.selected ? Font.DemiBold : Font.Normal
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
                        visible: devDelegate.modelData.label !== devDelegate.modelData.rawLabel
                        opacity: devMouse.containsMouse ? 1 : 0
                        text: devDelegate.modelData.rawLabel
                        font.pixelSize: ThemeModule.Theme.fontSizeCaption
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.overlay
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: devMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            if (!devDelegate.selected)
                                Services.EffectsService.picked(devDot, devMouse);
                            section.setDevice(devDelegate.modelData.node);
                        }
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingXL

        Section {
            output: true
            presented: root.presented
            visible: root.mode === "output" || root.mode === "combined"
        }

        Section {
            output: false
            presented: root.presented
            visible: root.mode === "input" || root.mode === "combined"
        }
    }
}
