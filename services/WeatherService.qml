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

    // A failed lookup (often no network yet at login) retries sooner than the
    // regular refresh.
    Timer {
        id: retryTimer
        interval: 120000
        repeat: false
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
            retryTimer.stop();
            weatherProc.running = false;
            root.currentWeatherStr = "";
        }
    }

    function fetchWeather() {
        if (!root.enabled)
            return;
        if (!weatherProc.running) {
            var loc = String(root.location || "").trim();
            var url = "https://wttr.in/" + (loc !== "" ? encodeURIComponent(loc) : "") + "?format=%c+%t+%l";
            weatherProc.command = ["curl", "-fsS", "--proto", "=https", "--max-time", "8", url];
            weatherProc.running = true;
        } else {
            root.fetchQueued = true;
        }
    }

    Process {
        id: weatherProc
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
            if (exitCode !== 0 && root.enabled)
                retryTimer.restart();
            else
                retryTimer.stop();

            if (root.fetchQueued) {
                root.fetchQueued = false;
                root.fetchWeather();
            }
        }
    }
}
