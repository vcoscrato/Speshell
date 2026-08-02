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

    // "output" = speaker/sink control, "input" = mic/source control
    property string mode: "output"

    readonly property bool isOutput: mode === "output"

    // ── Service properties (resolve once based on mode) ────
    readonly property var defaultDevice: isOutput
        ? Services.AudioService.defaultSink
        : Services.AudioService.defaultSource

    readonly property int serviceVolumePercent: isOutput
        ? Services.AudioService.outputVolumePercent
        : Services.AudioService.inputVolumePercent

    readonly property bool serviceHasVolume: isOutput
        ? Services.AudioService.hasOutputVolume
        : Services.AudioService.hasInputVolume

    readonly property bool serviceMuted: isOutput
        ? Services.AudioService.outputMuted
        : Services.AudioService.inputMuted

    // ── Local dragging state (preserves external volume sync) ──
    property bool localDragging: false
    property int localVolumePercent: 0

    // ── Node list ──────────────────────────────────────────
    readonly property var deviceEntries: {
        if (!root.dashboardActive || !Pipewire.nodes || !Pipewire.nodes.values)
            return [];

        var values = Pipewire.nodes.values;
        var result = [];
        for (var i = 0; i < values.length; i++) {
            var node = values[i];
            if (!node)
                continue;
            if (root.isOutput) {
                if ((node.isSink || false) && !node.isStream) {
                    var outputEntry = root.buildDeviceEntry(node);
                    if (outputEntry)
                        result.push(outputEntry);
                }
            } else {
                if (root.isSourceNode(node)) {
                    var inputEntry = root.buildDeviceEntry(node);
                    if (inputEntry)
                        result.push(inputEntry);
                }
            }
        }

        if (root.quickSwitchDevices && root.quickSwitchDevices.length > 0) {
            result.sort(function(a, b) {
                if (a.matchIndex !== b.matchIndex)
                    return a.matchIndex - b.matchIndex;
                return a.rawLabel.localeCompare(b.rawLabel);
            });
        }

        return result;
    }

    // ── Filtering ──────────────────────────────────────────
    // Output uses exact substring match; Input uses case-insensitive match.
    // Display-name overrides win over quick-switch labels, which win over raw names.
    function rawDeviceLabel(node) {
        return node.description || node.name || "Unknown";
    }

    function pushDeviceNameCandidate(candidates, value) {
        if (value === undefined || value === null)
            return;

        var text = String(value);
        if (text !== "" && candidates.indexOf(text) === -1)
            candidates.push(text);

        var trimmed = text.trim();
        if (trimmed !== "" && candidates.indexOf(trimmed) === -1)
            candidates.push(trimmed);
    }

    function deviceNameCandidates(node, rawLabel) {
        var candidates = [];
        if (node) {
            root.pushDeviceNameCandidate(candidates, node.name);
            root.pushDeviceNameCandidate(candidates, node.description);
        }
        root.pushDeviceNameCandidate(candidates, rawLabel);
        return candidates;
    }

    function mappedDeviceLabel(node, rawLabel) {
        var names = root.deviceDisplayNames;
        if (!names || typeof names !== "object")
            return "";

        var candidates = root.deviceNameCandidates(node, rawLabel);
        for (var i = 0; i < candidates.length; i++) {
            var key = candidates[i];
            if (key in names) {
                var mapped = names[key];
                if (mapped !== undefined && mapped !== null && String(mapped).trim() !== "")
                    return String(mapped);
            }
        }

        return "";
    }

    function displayLabel(node, rawLabel, fallbackLabel) {
        var mapped = root.mappedDeviceLabel(node, rawLabel);
        if (mapped !== "")
            return mapped;
        return fallbackLabel || rawLabel;
    }

    function deviceMatch(node) {
        var rawLabel = root.rawDeviceLabel(node);

        if (!root.quickSwitchDevices || root.quickSwitchDevices.length === 0)
            return { matches: true, label: root.displayLabel(node, rawLabel, rawLabel), matchIndex: -1 };

        if (root.isOutput) {
            var desc = node.description || "";
            for (var i = 0; i < root.quickSwitchDevices.length; i++) {
                var outputLabel = (root.quickSwitchDevices[i] || "").toString();
                if (outputLabel !== "" && desc.indexOf(outputLabel) !== -1)
                    return { matches: true, label: root.displayLabel(node, rawLabel, outputLabel), matchIndex: i };
            }
            return { matches: false, label: "", matchIndex: -1 };
        }

        // Input: case-insensitive with trim
        var descLower = (node.description || node.name || "").toLowerCase();
        for (var j = 0; j < root.quickSwitchDevices.length; j++) {
            var needle = (root.quickSwitchDevices[j] || "").toString().trim().toLowerCase();
            if (needle !== "") {
                var inputLabel = (root.quickSwitchDevices[j] || "").toString().trim();
                if (descLower.indexOf(needle) !== -1)
                    return { matches: true, label: root.displayLabel(node, rawLabel, inputLabel || rawLabel), matchIndex: j };
            }
        }
        return { matches: false, label: "", matchIndex: -1 };
    }

    function buildDeviceEntry(node) {
        var match = root.deviceMatch(node);
        if (!match.matches)
            return null;

        var rawLabel = root.rawDeviceLabel(node);
        return {
            node: node,
            label: match.label || rawLabel,
            rawLabel: rawLabel,
            matchIndex: match.matchIndex
        };
    }

    // Source node detection — only used for input mode.
    // Preserves the exact heuristics from the original AudioInputControl.
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

        var nodeDesc = typeof node.description === "string" ? node.description : "";
        if (nodeDesc.indexOf("Monitor of ") === 0)
            return false;

        return false;
    }

    // ── Service interaction ────────────────────────────────
    function setVolumePercent(pct) {
        if (root.isOutput)
            Services.AudioService.setOutputVolumePercent(pct);
        else
            Services.AudioService.setInputVolumePercent(pct);
    }

    function toggleMute() {
        if (root.isOutput)
            Services.AudioService.toggleOutputMute();
        else
            Services.AudioService.toggleInputMute();
    }

    function setDefaultDevice(node) {
        if (root.isOutput) {
            if (!node.isStream)
                Pipewire.preferredDefaultAudioSink = node;
        } else {
            Pipewire.preferredDefaultAudioSource = node;
        }
    }

    // ── Sync from AudioService (respects local dragging) ──
    Component.onCompleted: {
        localVolumePercent = root.serviceVolumePercent;
    }

    Connections {
        target: Services.AudioService
        function onOutputVolumePercentChanged() {
            if (root.isOutput && !root.localDragging)
                root.localVolumePercent = Services.AudioService.outputVolumePercent;
        }
        function onInputVolumePercentChanged() {
            if (!root.isOutput && !root.localDragging)
                root.localVolumePercent = Services.AudioService.inputVolumePercent;
        }
    }

    // ── UI ─────────────────────────────────────────────────
    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium

        // ── Volume slider ────────────────────────
        Row {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall

            Components.IconButton {
                iconName: root.serviceMuted
                    ? (root.isOutput ? "audio-output-muted" : "audio-input-muted")
                    : (root.isOutput ? "audio-output" : "audio-input")
                size: 32
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: root.serviceMuted
                    ? (root.isOutput ? "Unmute output" : "Unmute input")
                    : (root.isOutput ? "Mute output" : "Mute input")
                onClicked: root.toggleMute()
            }

            Components.StyledSlider {
                width: parent.width - 88 // 32 (icon) + 8 (spacing) + 8 (spacing) + 40 (text) = 88
                anchors.verticalCenter: parent.verticalCenter
                value: root.localDragging ? root.localVolumePercent : (root.serviceHasVolume ? root.serviceVolumePercent : 0)
                enabled: root.defaultDevice && root.serviceHasVolume
                onMoved: {
                    root.localVolumePercent = Math.round(value);
                    root.setVolumePercent(root.localVolumePercent);
                }
                onPressedChanged: {
                    root.localDragging = pressed;
                    if (!pressed)
                        root.setVolumePercent(root.localVolumePercent);
                }
            }

            Text {
                text: !root.defaultDevice
                    ? "—"
                    : (root.serviceHasVolume
                        ? root.serviceVolumePercent + "%"
                        : "…")
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext
                width: 40
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // ── Device list ────────────────────────────
        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingTiny

            Repeater {
                model: root.deviceEntries

                delegate: Rectangle {
                    id: deviceDelegate
                    required property var modelData
                    property var entry: deviceDelegate.modelData
                    property var node: deviceDelegate.entry.node
                    width: parent.width
                    height: 32
                    radius: ThemeModule.Theme.borderRadiusSmall
                    color: deviceMouse.containsMouse ? ThemeModule.Theme.cardHover : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: ThemeModule.Theme.animDuration }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: ThemeModule.Theme.spacingSmall
                        spacing: ThemeModule.Theme.spacingSmall

                        Rectangle {
                            width: 14
                            height: 14
                            radius: 7
                            anchors.verticalCenter: parent.verticalCenter
                            border.width: 2
                            border.color: ThemeModule.Theme.accent
                            color: (root.defaultDevice === deviceDelegate.node) ? ThemeModule.Theme.accent : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: ThemeModule.Theme.animDuration }
                            }
                        }

                        Text {
                            text: deviceDelegate.entry.label
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.text
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: deviceMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            root.setDefaultDevice(deviceDelegate.node);
                        }
                    }
                }
            }
        }
    }
}
