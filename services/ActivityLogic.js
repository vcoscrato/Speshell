.pragma library

var activeStates = ["active", "busy", "paused", "error"];
var inactiveStates = ["idle", "inactive", "stopped", "complete"];
var tones = ["neutral", "success", "warning", "error", "info"];

function normalizedState(value) {
    var state = String(value || "").trim().toLowerCase();
    if (activeStates.indexOf(state) >= 0)
        return state;
    if (inactiveStates.indexOf(state) >= 0)
        return "inactive";
    return "";
}

function normalizedTone(value) {
    var tone = String(value || "neutral").trim().toLowerCase();
    return tones.indexOf(tone) >= 0 ? tone : "neutral";
}

function normalizedId(value) {
    var id = String(value || "").trim().toLowerCase();
    return /^[a-z0-9][a-z0-9._-]*$/.test(id) ? id : "";
}

function normalizedProvider(value) {
    var provider = normalizedId(value);
    return provider !== "" ? provider : "unknown";
}

function finiteNumber(value, fallback) {
    var number = Number(value);
    return isFinite(number) ? number : fallback;
}

function normalizedActions(value) {
    if (!Array.isArray(value))
        return [];

    var result = [];
    var seen = ({});
    for (var i = 0; i < value.length; i++) {
        var supplied = value[i] || ({});
        var id = normalizedId(supplied.id);
        if (id === "" || Object.prototype.hasOwnProperty.call(seen, id))
            continue;
        seen[id] = true;
        result.push({
            id: id,
            label: String(supplied.label || id).trim(),
            iconName: String(supplied.iconName || "").trim(),
            tone: normalizedTone(supplied.tone)
        });
    }
    return result;
}

function normalizeEntry(providerValue, suppliedValue, previousValue, nowValue) {
    var supplied = suppliedValue || ({});
    var state = normalizedState(supplied.state);
    var id = normalizedId(supplied.id);
    if (id === "" || state === "" || state === "inactive")
        return null;

    var provider = normalizedProvider(providerValue);
    var previous = previousValue || null;
    var now = finiteNumber(nowValue, Date.now());
    var startedAt = previous && previous.id === id
        ? finiteNumber(previous.startedAt, now)
        : finiteNumber(supplied.startedAt, now);

    return {
        key: provider + ":" + id,
        provider: provider,
        id: id,
        state: state,
        label: String(supplied.label || id).trim(),
        detail: String(supplied.detail || "").trim(),
        iconName: String(supplied.iconName || "info").trim(),
        tone: normalizedTone(supplied.tone),
        actions: normalizedActions(supplied.actions),
        startedAt: startedAt,
        updatedAt: now,
        priority: finiteNumber(supplied.priority, 0),
        sortOrder: finiteNumber(supplied.sortOrder, 100)
    };
}

function flattenProviders(providersValue) {
    var providers = providersValue || ({});
    var winners = ({});
    var providerNames = Object.keys(providers);

    for (var i = 0; i < providerNames.length; i++) {
        var entries = providers[providerNames[i]] || ({});
        var ids = Object.keys(entries);
        for (var j = 0; j < ids.length; j++) {
            var candidate = entries[ids[j]];
            var current = winners[candidate.id];
            if (!current
                    || candidate.priority > current.priority
                    || (candidate.priority === current.priority
                        && candidate.updatedAt >= current.updatedAt))
                winners[candidate.id] = candidate;
        }
    }

    var result = Object.keys(winners).map(function(id) { return winners[id]; });
    result.sort(function(left, right) {
        if (left.sortOrder !== right.sortOrder)
            return left.sortOrder - right.sortOrder;
        if (left.startedAt !== right.startedAt)
            return left.startedAt - right.startedAt;
        return left.id.localeCompare(right.id);
    });
    return result;
}

function elapsedText(startedAtValue, nowValue) {
    var now = finiteNumber(nowValue, Date.now());
    var startedAt = finiteNumber(startedAtValue, now);
    var seconds = Math.max(0, Math.floor((now - startedAt) / 1000));
    if (seconds < 60)
        return seconds + "s";

    var minutes = Math.floor(seconds / 60);
    if (minutes < 60)
        return minutes + "m " + (seconds % 60) + "s";

    var hours = Math.floor(minutes / 60);
    return hours + "h " + (minutes % 60) + "m";
}

var shellNames = ["sh", "bash", "dash", "zsh"];

function commandName(value) {
    var path = String(value || "");
    return path.substring(path.lastIndexOf("/") + 1);
}

// Reads `ps -e -o args=` output. Matching on argv[0] (or the script run by a
// shell) avoids false positives from editors or pagers that mention a tool.
function detectProcessActivities(psOutput) {
    var recording = false;
    var dictationToggle = false;
    var dictationRecording = false;
    var dictationTranscribing = false;
    var lines = String(psOutput || "").split("\n");

    for (var i = 0; i < lines.length; i++) {
        var args = lines[i].trim().split(/\s+/);
        var name = commandName(args[0]);
        if (shellNames.indexOf(name) >= 0 && commandName(args[1]) === "dictate-toggle")
            name = "dictate-toggle";
        var dictationFile = lines[i].indexOf("dictate.wav") >= 0;

        if (name === "wf-recorder")
            recording = true;
        else if (name === "dictate-toggle")
            dictationToggle = true;
        else if (name === "pw-record" && dictationFile)
            dictationRecording = true;
        else if (name === "whisper-cli" && dictationFile)
            dictationTranscribing = true;
    }

    var entries = [];
    if (recording) {
        entries.push({
            id: "screen-recording",
            state: "active",
            label: "Screen recording",
            detail: "Recording display",
            iconName: "screen-recording",
            tone: "error",
            priority: 10,
            sortOrder: 0,
            actions: [{ id: "stop", label: "Stop", iconName: "close", tone: "error" }]
        });
    }
    if (dictationTranscribing || (dictationToggle && !dictationRecording)) {
        entries.push({
            id: "dictation",
            state: "busy",
            label: "Dictation",
            detail: "Transcribing…",
            iconName: "loader",
            tone: "info",
            priority: 10,
            sortOrder: 1
        });
    } else if (dictationRecording) {
        entries.push({
            id: "dictation",
            state: "active",
            label: "Dictation",
            detail: "Listening…",
            iconName: "audio-input",
            tone: "info",
            priority: 10,
            sortOrder: 1,
            actions: [{ id: "finish", label: "Finish", iconName: "check", tone: "info" }]
        });
    }
    return entries;
}
