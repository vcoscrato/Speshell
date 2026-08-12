pragma Singleton
// qmllint disable signal-handler-parameters

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource

    property int outputVolumePercent: 0
    property bool hasOutputVolume: false
    property bool outputMuted: false

    property int inputVolumePercent: 0
    property bool hasInputVolume: false
    property bool inputMuted: false
    property bool preferWpctlWrites: true

    readonly property int maxParseRetries: 12
    property int outputParseRetryCount: 0
    property int inputParseRetryCount: 0
    property int pendingOutputVolumePercent: 0
    property bool outputVolumeQueued: false
    property bool pendingOutputMuted: false
    property bool outputMuteQueued: false
    property int pendingInputVolumePercent: 0
    property bool inputVolumeQueued: false
    property bool pendingInputMuted: false
    property bool inputMuteQueued: false
    property bool outputReadQueued: false
    property bool inputReadQueued: false
    property bool outputOsdInitialized: false
    property double outputOsdSuppressedUntil: 0

    signal outputOsdRequested(int volumePercent, bool muted)

    function clampPercent(value) {
        return Math.max(0, Math.min(100, Math.round(Number(value) || 0)));
    }

    function suppressOutputOsd(durationMs) {
        root.outputOsdSuppressedUntil = Math.max(
            root.outputOsdSuppressedUntil,
            Date.now() + Math.max(0, Number(durationMs) || 0)
        );
        outputOsdDebounce.stop();
    }

    function queueOutputOsd() {
        if (!root.outputOsdInitialized || Date.now() < root.outputOsdSuppressedUntil)
            return;
        outputOsdDebounce.restart();
    }

    function extractNumericVolume(value) {
        if (value === null || value === undefined)
            return NaN;

        var num = Number(value);
        if (isFinite(num))
            return num;

        if (Array.isArray(value)) {
            if (value.length === 0)
                return NaN;
            var sum = 0;
            var count = 0;
            for (var i = 0; i < value.length; i++) {
                var n = root.extractNumericVolume(value[i]);
                if (isFinite(n)) {
                    sum += n;
                    count++;
                }
            }
            return count > 0 ? (sum / count) : NaN;
        }

        if (typeof value === "object") {
            var preferred = ["value", "linear", "avg", "average", "master", "vol", "volume"];
            for (var j = 0; j < preferred.length; j++) {
                var key = preferred[j];
                if (!(key in value))
                    continue;
                var v = root.extractNumericVolume(value[key]);
                if (isFinite(v))
                    return v;
            }

            var keys = Object.keys(value);
            for (var k = 0; k < keys.length; k++) {
                var nested = root.extractNumericVolume(value[keys[k]]);
                if (isFinite(nested))
                    return nested;
            }
        }

        return NaN;
    }

    function parseVolumePercent(audioObject) {
        if (!audioObject)
            return -1;

        var numeric = root.extractNumericVolume(audioObject.volume);
        if (!isFinite(numeric))
            return -1;

        // QuickShell volume is linear 0..1 in normal cases.
        return root.clampPercent(numeric * 100);
    }

    function retryOutputSync() {
        if (root.outputParseRetryCount >= root.maxParseRetries)
            root.requestOutputRead();
        else {
            root.outputParseRetryCount += 1;
            outputRetryTimer.restart();
        }
    }

    function retryInputSync() {
        if (root.inputParseRetryCount >= root.maxParseRetries)
            root.requestInputRead();
        else {
            root.inputParseRetryCount += 1;
            inputRetryTimer.restart();
        }
    }

    function requestOutputRead() {
        root.outputReadQueued = true;
        root.startOutputRead();
    }

    function requestInputRead() {
        root.inputReadQueued = true;
        root.startInputRead();
    }

    function startOutputRead() {
        if (!root.outputReadQueued || wpctlOutputReadProc.running)
            return;
        root.outputReadQueued = false;
        wpctlOutputReadProc.running = true;
    }

    function startInputRead() {
        if (!root.inputReadQueued || wpctlInputReadProc.running)
            return;
        root.inputReadQueued = false;
        wpctlInputReadProc.running = true;
    }

    function syncOutputFromPipewire() {
        var sink = root.defaultSink;
        if (!sink || !sink.audio) {
            root.hasOutputVolume = false;
            root.outputMuted = false;
            root.outputParseRetryCount = 0;
            return;
        }

        root.outputMuted = !!sink.audio.muted;

        var percent = root.parseVolumePercent(sink.audio);
        if (percent < 0) {
            root.retryOutputSync();
            return;
        }

        root.outputVolumePercent = percent;
        root.hasOutputVolume = true;
        root.outputParseRetryCount = 0;
    }

    function syncInputFromPipewire() {
        var source = root.defaultSource;
        if (!source || !source.audio) {
            root.hasInputVolume = false;
            root.inputMuted = false;
            root.inputParseRetryCount = 0;
            return;
        }

        root.inputMuted = !!source.audio.muted;

        var percent = root.parseVolumePercent(source.audio);
        if (percent < 0) {
            root.retryInputSync();
            return;
        }

        root.inputVolumePercent = percent;
        root.hasInputVolume = true;
        root.inputParseRetryCount = 0;
    }

    function setOutputVolumePercent(percent) {
        var next = root.clampPercent(percent);
        root.suppressOutputOsd(1200);
        root.outputVolumePercent = next;
        root.hasOutputVolume = true;
        root.pendingOutputVolumePercent = next;

        if (root.preferWpctlWrites) {
            root.outputVolumeQueued = true;
            root.startOutputVolumeWrite();
            return;
        }

        if (root.defaultSink && root.defaultSink.audio) {
            root.defaultSink.audio.volume = next / 100.0;
            if (next > 0)
                root.defaultSink.audio.muted = false;
            root.syncOutputFromPipewire();
            return;
        }

        root.outputVolumeQueued = true;
        root.startOutputVolumeWrite();
    }

    function setInputVolumePercent(percent) {
        var next = root.clampPercent(percent);
        root.inputVolumePercent = next;
        root.hasInputVolume = true;
        root.pendingInputVolumePercent = next;

        if (root.preferWpctlWrites) {
            root.inputVolumeQueued = true;
            root.startInputVolumeWrite();
            return;
        }

        if (root.applyInputVolumeDirect(next)) {
            return;
        }

        root.inputVolumeQueued = true;
        root.startInputVolumeWrite();
    }

    function applyOutputVolumeDirect(percent) {
        if (!(root.defaultSink && root.defaultSink.audio))
            return false;

        root.defaultSink.audio.volume = percent / 100.0;
        if (percent > 0)
            root.defaultSink.audio.muted = false;
        root.syncOutputFromPipewire();
        return true;
    }

    function applyInputVolumeDirect(percent) {
        if (!(root.defaultSource && root.defaultSource.audio))
            return false;

        root.defaultSource.audio.volume = percent / 100.0;
        if (percent > 0)
            root.defaultSource.audio.muted = false;
        root.syncInputFromPipewire();
        return true;
    }

    function applyOutputMuteDirect(muted) {
        if (!(root.defaultSink && root.defaultSink.audio))
            return false;

        root.defaultSink.audio.muted = !!muted;
        root.syncOutputFromPipewire();
        return true;
    }

    function applyInputMuteDirect(muted) {
        if (!(root.defaultSource && root.defaultSource.audio))
            return false;

        root.defaultSource.audio.muted = !!muted;
        root.syncInputFromPipewire();
        return true;
    }

    function disableWpctlWrites() {
        if (!root.preferWpctlWrites)
            return;

        root.preferWpctlWrites = false;
    }

    function setOutputMuted(muted) {
        var next = !!muted;
        root.suppressOutputOsd(1200);
        root.outputMuted = next;
        root.pendingOutputMuted = next;
        root.outputMuteQueued = true;
        root.startOutputMuteWrite();
    }

    function setInputMuted(muted) {
        var next = !!muted;
        root.inputMuted = next;
        root.pendingInputMuted = next;
        root.inputMuteQueued = true;
        root.startInputMuteWrite();
    }

    function toggleOutputMute() {
        root.setOutputMuted(!root.outputMuted);
    }

    function toggleInputMute() {
        root.setInputMuted(!root.inputMuted);
    }

    function startOutputMuteWrite() {
        if (!root.outputMuteQueued || wpctlOutputMuteProc.running)
            return;
        root.outputMuteQueued = false;
        if (!root.preferWpctlWrites && root.applyOutputMuteDirect(root.pendingOutputMuted))
            return;
        wpctlOutputMuteProc.command = [
            "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", root.pendingOutputMuted ? "1" : "0"
        ];
        wpctlOutputMuteProc.running = true;
    }

    function startInputMuteWrite() {
        if (!root.inputMuteQueued || wpctlInputMuteProc.running)
            return;
        root.inputMuteQueued = false;
        if (!root.preferWpctlWrites && root.applyInputMuteDirect(root.pendingInputMuted))
            return;
        wpctlInputMuteProc.command = [
            "wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", root.pendingInputMuted ? "1" : "0"
        ];
        wpctlInputMuteProc.running = true;
    }

    function startOutputVolumeWrite() {
        if (!root.outputVolumeQueued || wpctlOutputSetProc.running)
            return;

        if (!root.preferWpctlWrites) {
            root.outputVolumeQueued = false;
            root.applyOutputVolumeDirect(root.pendingOutputVolumePercent);
            return;
        }

        root.outputVolumeQueued = false;
        var pct = root.pendingOutputVolumePercent;
        var cmd = "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + pct + "%";
        if (pct > 0)
            cmd = "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 && " + cmd;
        wpctlOutputSetProc.command = ["sh", "-c", cmd];
        wpctlOutputSetProc.running = true;
    }

    function startInputVolumeWrite() {
        if (!root.inputVolumeQueued || wpctlInputSetProc.running)
            return;

        if (!root.preferWpctlWrites) {
            root.inputVolumeQueued = false;
            root.applyInputVolumeDirect(root.pendingInputVolumePercent);
            return;
        }

        root.inputVolumeQueued = false;
        var pct = root.pendingInputVolumePercent;
        var cmd = "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + pct + "%";
        if (pct > 0)
            cmd = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 && " + cmd;
        wpctlInputSetProc.command = ["sh", "-c", cmd];
        wpctlInputSetProc.running = true;
    }

    Component.onCompleted: {
        root.syncOutputFromPipewire();
        root.syncInputFromPipewire();
        root.outputOsdInitialized = true;
    }

    onDefaultSinkChanged: {
        root.suppressOutputOsd(1200);
        root.outputParseRetryCount = 0;
        root.hasOutputVolume = false;
        root.syncOutputFromPipewire();
        outputSwitchReadTimer.restart();
    }

    onDefaultSourceChanged: {
        root.inputParseRetryCount = 0;
        root.hasInputVolume = false;
        root.syncInputFromPipewire();
        inputSwitchReadTimer.restart();
    }

    onOutputVolumePercentChanged: root.queueOutputOsd()
    onOutputMutedChanged: root.queueOutputOsd()

    Timer {
        id: outputRetryTimer
        interval: 120
        running: false
        repeat: false
        onTriggered: root.syncOutputFromPipewire()
    }

    Timer {
        id: outputOsdDebounce
        interval: 30
        running: false
        repeat: false
        onTriggered: {
            if (root.outputOsdInitialized && Date.now() >= root.outputOsdSuppressedUntil)
                root.outputOsdRequested(root.outputVolumePercent, root.outputMuted);
        }
    }

    Timer {
        id: outputSwitchReadTimer
        interval: 120
        running: false
        repeat: false
        onTriggered: root.requestOutputRead()
    }

    Timer {
        id: inputRetryTimer
        interval: 120
        running: false
        repeat: false
        onTriggered: root.syncInputFromPipewire()
    }

    Timer {
        id: inputSwitchReadTimer
        interval: 120
        running: false
        repeat: false
        onTriggered: root.requestInputRead()
    }

    PwObjectTracker {
        objects: root.defaultSink ? [root.defaultSink] : []
    }

    PwObjectTracker {
        objects: root.defaultSource ? [root.defaultSource] : []
    }

    Connections {
        target: root.defaultSink && root.defaultSink.audio ? root.defaultSink.audio : null
        function onVolumeChanged() {
            root.syncOutputFromPipewire();
        }
        function onMutedChanged() {
            root.syncOutputFromPipewire();
        }
    }

    Connections {
        target: root.defaultSource && root.defaultSource.audio ? root.defaultSource.audio : null
        function onVolumeChanged() {
            root.syncInputFromPipewire();
        }
        function onMutedChanged() {
            root.syncInputFromPipewire();
        }
    }

    Process {
        id: wpctlOutputSetProc
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "50%"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.disableWpctlWrites();
                root.applyOutputVolumeDirect(root.pendingOutputVolumePercent);
            }
            if (root.outputVolumeQueued) {
                root.startOutputVolumeWrite();
                return;
            }
            root.requestOutputRead();
        }
    }

    Process {
        id: wpctlInputSetProc
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", "50%"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.disableWpctlWrites();
                root.applyInputVolumeDirect(root.pendingInputVolumePercent);
            }
            if (root.inputVolumeQueued) {
                root.startInputVolumeWrite();
                return;
            }
            root.requestInputRead();
        }
    }

    Process {
        id: wpctlOutputMuteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.disableWpctlWrites();
                root.applyOutputMuteDirect(root.pendingOutputMuted);
            }
            if (root.outputMuteQueued) {
                root.startOutputMuteWrite();
                return;
            }
            root.requestOutputRead();
        }
    }

    Process {
        id: wpctlInputMuteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.disableWpctlWrites();
                root.applyInputMuteDirect(root.pendingInputMuted);
            }
            if (root.inputMuteQueued) {
                root.startInputMuteWrite();
                return;
            }
            root.requestInputRead();
        }
    }

    Process {
        id: wpctlOutputReadProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var match = (line || "").match(/Volume:\s*([0-9.]+)/);
                if (!match)
                    return;

                var volume = Number(match[1]);
                if (!isFinite(volume))
                    return;

                root.outputVolumePercent = root.clampPercent(volume * 100);
                root.hasOutputVolume = true;
                root.outputMuted = (line || "").indexOf("MUTED") !== -1;
                root.outputParseRetryCount = 0;
            }
        }
    }

    Process {
        id: wpctlInputReadProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var match = (line || "").match(/Volume:\s*([0-9.]+)/);
                if (!match)
                    return;

                var volume = Number(match[1]);
                if (!isFinite(volume))
                    return;

                root.inputVolumePercent = root.clampPercent(volume * 100);
                root.hasInputVolume = true;
                root.inputMuted = (line || "").indexOf("MUTED") !== -1;
                root.inputParseRetryCount = 0;
            }
        }
    }
}
