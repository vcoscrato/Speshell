pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default output and input volume through Quickshell's PipeWire bindings.
Singleton {
    id: root

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource
    readonly property var sinkAudio: root.defaultSink && root.defaultSink.ready ? root.defaultSink.audio : null
    readonly property var sourceAudio: root.defaultSource && root.defaultSource.ready ? root.defaultSource.audio : null

    readonly property bool hasOutputVolume: root.sinkAudio !== null
    readonly property int outputVolumePercent: root.sinkAudio ? root.clampPercent(root.sinkAudio.volume * 100) : 0
    readonly property bool outputMuted: root.sinkAudio ? root.sinkAudio.muted : false

    readonly property bool hasInputVolume: root.sourceAudio !== null
    readonly property int inputVolumePercent: root.sourceAudio ? root.clampPercent(root.sourceAudio.volume * 100) : 0
    readonly property bool inputMuted: root.sourceAudio ? root.sourceAudio.muted : false

    property int scrollStep: 5
    property double outputOsdSuppressedUntil: 0

    // Emitted for output changes made outside Speshell, such as media keys.
    signal outputOsdRequested(int volumePercent, bool muted)

    function clampPercent(value) {
        return Math.max(0, Math.min(100, Math.round(Number(value) || 0)));
    }

    function suppressOutputOsd(durationMs) {
        root.outputOsdSuppressedUntil = Math.max(root.outputOsdSuppressedUntil, Date.now() + durationMs);
        outputOsdDebounce.stop();
    }

    function queueOutputOsd() {
        if (root.hasOutputVolume && Date.now() >= root.outputOsdSuppressedUntil)
            outputOsdDebounce.restart();
    }

    function setVolume(audio, percent) {
        if (!audio)
            return;
        var next = root.clampPercent(percent);
        if (next > 0 && audio.muted)
            audio.muted = false;
        audio.volume = next / 100;
    }

    function setOutputVolumePercent(percent) {
        root.suppressOutputOsd(1200);
        root.setVolume(root.sinkAudio, percent);
    }

    function setInputVolumePercent(percent) {
        root.setVolume(root.sourceAudio, percent);
    }

    function toggleOutputMute() {
        if (!root.sinkAudio)
            return;
        root.suppressOutputOsd(1200);
        root.sinkAudio.muted = !root.sinkAudio.muted;
    }

    function toggleInputMute() {
        if (root.sourceAudio)
            root.sourceAudio.muted = !root.sourceAudio.muted;
    }

    // Moves volume by one configured scroll step; direction is positive or negative.
    function stepOutputVolume(direction) {
        if (direction)
            root.setOutputVolumePercent(root.outputVolumePercent + (direction > 0 ? root.scrollStep : -root.scrollStep));
    }

    function stepInputVolume(direction) {
        if (direction)
            root.setInputVolumePercent(root.inputVolumePercent + (direction > 0 ? root.scrollStep : -root.scrollStep));
    }

    function setDefaultSink(node) {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        if (node)
            Pipewire.preferredDefaultAudioSource = node;
    }

    // Switching devices or binding a new one changes the values without a
    // user volume change, so keep the OSD quiet for a moment.
    onDefaultSinkChanged: root.suppressOutputOsd(1200)
    onHasOutputVolumeChanged: root.suppressOutputOsd(1200)

    PwObjectTracker {
        objects: [root.defaultSink, root.defaultSource].filter(function(node) { return !!node; })
    }

    Connections {
        target: root.sinkAudio

        function onVolumesChanged() { root.queueOutputOsd(); }
        function onMutedChanged() { root.queueOutputOsd(); }
    }

    Timer {
        id: outputOsdDebounce
        interval: 30
        repeat: false
        onTriggered: {
            if (Date.now() >= root.outputOsdSuppressedUntil)
                root.outputOsdRequested(root.outputVolumePercent, root.outputMuted);
        }
    }
}
