pragma Singleton
// qmllint disable signal-handler-parameters
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property string currentWeatherStr: ""
    property string location: ""
    property bool fetchQueued: false

    function normalizeWeatherText(text, exitCode, errorText) {
        var trimmed = (text || "").trim();
        var error = (errorText || "").trim().toLowerCase();

        if (exitCode === 0 && trimmed.length > 0
                && !trimmed.includes("Sorry")
                && !trimmed.includes("Unknown")) {
            return trimmed;
        }

        if (error.indexOf("command not found") !== -1 || error.indexOf("not found") !== -1) {
            return "Weather unavailable";
        }

        if (exitCode !== 0 || trimmed === "") {
            return "Weather offline";
        }

        return "Weather unavailable";
    }

    Timer {
        interval: 1800000 // 30 mins
        running: root.enabled
        repeat: true
        triggeredOnStart: false
        onTriggered: root.fetchWeather()
    }

    onLocationChanged: {
        if (root.enabled)
            root.fetchWeather();
    }

    onEnabledChanged: {
        if (root.enabled) {
            root.currentWeatherStr = "Loading...";
            root.fetchWeather();
        } else {
            root.fetchQueued = false;
            weatherProc.running = false;
            root.currentWeatherStr = "";
        }
    }

    function fetchWeather() {
        if (!root.enabled)
            return;
        if (!weatherProc.running) {
            var loc = String(root.location || "").trim();
            var url = loc !== "" ? ("wttr.in/" + encodeURIComponent(loc) + "?format=%c+%t+%l") : "wttr.in/?format=%c+%t+%l";
            weatherProc.command = ["curl", "-fsS", "--max-time", "8", url];
            weatherProc.running = true;
        } else {
            root.fetchQueued = true;
        }
    }

    Process {
        id: weatherProc
        command: ["curl", "-fsS", "--max-time", "8", "wttr.in/?format=%c+%t+%l"]
        running: false

        property string output: ""
        property string errorOutput: ""

        onRunningChanged: {
            if (running) {
                weatherProc.output = "";
                weatherProc.errorOutput = "";
            }
        }

        stdout: SplitParser {
            onRead: function(data) {
                weatherProc.output += data;
            }
        }

        stderr: SplitParser {
            onRead: function(data) {
                weatherProc.errorOutput += data;
            }
        }

        onExited: function(exitCode) {
            var text = weatherProc.output.trim();
            var errorText = weatherProc.errorOutput.trim();
            weatherProc.output = "";
            weatherProc.errorOutput = "";
            root.currentWeatherStr = root.normalizeWeatherText(text, exitCode, errorText);

            if (root.fetchQueued) {
                root.fetchQueued = false;
                root.fetchWeather();
            }
        }
    }
}
