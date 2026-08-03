pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Pipewire
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root

    property bool dashboardActive: true
    property var quickSwitchDevices: []
    property var deviceDisplayNames: ({})
    property var inputQuickSwitchDevices: []
    property var inputDeviceDisplayNames: ({})

    // "output" = speaker, "input" = mic, "combined" = both speaker & mic in one card
    property string mode: "output"

    readonly property bool isCombined: mode === "combined"
    readonly property bool isOutput: mode === "output" || isCombined

    function buildNodeList(isOut) {
        if (!root.dashboardActive || !Pipewire.nodes || !Pipewire.nodes.values)
            return [];

        var values = Pipewire.nodes.values;
        var result = [];
        for (var i = 0; i < values.length; i++) {
            var node = values[i];
            if (!node)
                continue;
            if (isOut) {
                if ((node.isSink || false) && !node.isStream) {
                    var outEntry = root.buildDeviceEntry(node, true);
                    if (outEntry)
                        result.push(outEntry);
                }
            } else {
                if (root.isSourceNode(node)) {
                    var inEntry = root.buildDeviceEntry(node, false);
                    if (inEntry)
                        result.push(inEntry);
                }
            }
        }

        var configuredDevices = root.quickSwitchFor(isOut);
        if (configuredDevices.length > 0) {
            result.sort(function(a, b) {
                if (a.matchIndex !== b.matchIndex)
                    return a.matchIndex - b.matchIndex;
                return a.rawLabel.localeCompare(b.rawLabel);
            });
        }
        return result;
    }

    function rawDeviceLabel(node) {
        return node.description || node.name || "Unknown";
    }

    function quickSwitchFor(isOut) {
        var configured = isOut || !root.isCombined
            ? root.quickSwitchDevices
            : root.inputQuickSwitchDevices;
        return Array.isArray(configured) ? configured : [];
    }

    function displayNamesFor(isOut) {
        var configured = isOut || !root.isCombined
            ? root.deviceDisplayNames
            : root.inputDeviceDisplayNames;
        return configured && typeof configured === "object" ? configured : ({});
    }

    function nameCandidates(node) {
        var candidates = [];
        var values = [node ? node.name : "", node ? node.description : ""];
        for (var i = 0; i < values.length; i++) {
            var value = String(values[i] || "").trim();
            if (value !== "" && candidates.indexOf(value) < 0)
                candidates.push(value);
        }
        return candidates;
    }

    function mappedDeviceLabel(node, isOut) {
        var names = root.displayNamesFor(isOut);
        var candidates = root.nameCandidates(node);
        for (var i = 0; i < candidates.length; i++) {
            if (Object.prototype.hasOwnProperty.call(names, candidates[i])) {
                var mapped = String(names[candidates[i]] || "").trim();
                if (mapped !== "")
                    return mapped;
            }
        }
        return "";
    }

    function matchIndex(node, isOut) {
        var configured = root.quickSwitchFor(isOut);
        if (configured.length === 0)
            return -1;

        var candidates = root.nameCandidates(node);
        for (var configuredIndex = 0; configuredIndex < configured.length; configuredIndex++) {
            var needle = String(configured[configuredIndex] || "").trim().toLowerCase();
            if (needle === "")
                continue;
            for (var candidateIndex = 0; candidateIndex < candidates.length; candidateIndex++) {
                if (candidates[candidateIndex].toLowerCase().indexOf(needle) >= 0)
                    return configuredIndex;
            }
        }
        return -2;
    }

    function buildDeviceEntry(node, isOut) {
        var rawLabel = root.rawDeviceLabel(node);
        var matchedIndex = root.matchIndex(node, isOut);
        if (matchedIndex === -2)
            return null;
        var mappedLabel = root.mappedDeviceLabel(node, isOut);
        return {
            node: node,
            label: mappedLabel !== "" ? mappedLabel : rawLabel,
            rawLabel: rawLabel,
            matchIndex: matchedIndex
        };
    }

    function isSourceNode(node) {
        if (!node)
            return false;
        if (Boolean(node.isSource))
            return true;
        var mediaClass = typeof node.mediaClass === "string" ? node.mediaClass : "";
        if (mediaClass.indexOf("Audio/Source") === 0)
            return true;
        var name = typeof node.name === "string" ? node.name : "";
        if (name.indexOf(".monitor") !== -1)
            return false;
        if (name.indexOf("alsa_input.") === 0 || name.indexOf(".input.") !== -1)
            return true;
        var description = typeof node.description === "string" ? node.description : "";
        if (description.indexOf("Monitor of ") === 0)
            return false;
        return false;
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingLarge

        // ── OUTPUT CONTROL SECTION ────────────────────────
        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: root.mode === "output" || root.mode === "combined"

            Text {
                visible: root.isCombined
                text: "Volume"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                font.bold: true
                color: ThemeModule.Theme.text
            }

            Row {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Components.IconButton {
                    iconName: Services.AudioService.outputMuted ? "audio-output-muted" : "audio-output"
                    size: 32
                    anchors.verticalCenter: parent.verticalCenter
                    tooltipText: Services.AudioService.outputMuted ? "Unmute output" : "Mute output"
                    onClicked: Services.AudioService.toggleOutputMute()
                }

                Components.StyledSlider {
                    width: parent.width - 88
                    anchors.verticalCenter: parent.verticalCenter
                    value: Services.AudioService.hasOutputVolume ? Services.AudioService.outputVolumePercent : 0
                    enabled: Services.AudioService.defaultSink && Services.AudioService.hasOutputVolume
                    stepSize: (Services.ConfigService.config && Services.ConfigService.config.audioScrollStep)
                        ? Services.ConfigService.config.audioScrollStep
                        : 5
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
                    model: root.buildNodeList(true)

                    delegate: Rectangle {
                        id: outDevDelegate
                        required property var modelData
                        width: parent.width
                        height: 32
                        radius: ThemeModule.Theme.borderRadiusSmall
                        color: outDevMouse.containsMouse ? ThemeModule.Theme.cardHover : "transparent"

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: ThemeModule.Theme.spacingSmall
                            spacing: ThemeModule.Theme.spacingSmall

                            Rectangle {
                                width: 14; height: 14; radius: 7
                                anchors.verticalCenter: parent.verticalCenter
                                border.width: 2
                                border.color: ThemeModule.Theme.accent
                                color: (Services.AudioService.defaultSink === outDevDelegate.modelData.node) ? ThemeModule.Theme.accent : "transparent"
                            }

                            Text {
                                text: outDevDelegate.modelData.label
                                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                                font.family: ThemeModule.Theme.fontFamily
                                color: ThemeModule.Theme.text
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: outDevMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: Pipewire.preferredDefaultAudioSink = outDevDelegate.modelData.node
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

            Text {
                visible: root.isCombined
                text: "Microphone"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                font.bold: true
                color: ThemeModule.Theme.text
            }

            Row {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Components.IconButton {
                    iconName: Services.AudioService.inputMuted ? "audio-input-muted" : "audio-input"
                    size: 32
                    anchors.verticalCenter: parent.verticalCenter
                    tooltipText: Services.AudioService.inputMuted ? "Unmute input" : "Mute input"
                    onClicked: Services.AudioService.toggleInputMute()
                }

                Components.StyledSlider {
                    width: parent.width - 88
                    anchors.verticalCenter: parent.verticalCenter
                    value: Services.AudioService.hasInputVolume ? Services.AudioService.inputVolumePercent : 0
                    enabled: Services.AudioService.defaultSource && Services.AudioService.hasInputVolume
                    stepSize: (Services.ConfigService.config && Services.ConfigService.config.audioScrollStep)
                        ? Services.ConfigService.config.audioScrollStep
                        : 5
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
                    model: root.buildNodeList(false)

                    delegate: Rectangle {
                        id: inDevDelegate
                        required property var modelData
                        width: parent.width
                        height: 32
                        radius: ThemeModule.Theme.borderRadiusSmall
                        color: inDevMouse.containsMouse ? ThemeModule.Theme.cardHover : "transparent"

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: ThemeModule.Theme.spacingSmall
                            spacing: ThemeModule.Theme.spacingSmall

                            Rectangle {
                                width: 14; height: 14; radius: 7
                                anchors.verticalCenter: parent.verticalCenter
                                border.width: 2
                                border.color: ThemeModule.Theme.accent
                                color: (Services.AudioService.defaultSource === inDevDelegate.modelData.node) ? ThemeModule.Theme.accent : "transparent"
                            }

                            Text {
                                text: inDevDelegate.modelData.label
                                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                                font.family: ThemeModule.Theme.fontFamily
                                color: ThemeModule.Theme.text
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: inDevMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: Pipewire.preferredDefaultAudioSource = inDevDelegate.modelData.node
                        }
                    }
                }
            }
        }
    }
}
