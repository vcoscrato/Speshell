pragma Singleton
// qmllint disable signal-handler-parameters
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    // "", "loading", "ready", or "offline" (no answer; retried soon).
    property string status: ""
    property string temperature: ""
    property string condition: ""
    property string iconName: "weather-cloudy"
    property string location: ""
    property bool fetchQueued: false

    // wttr.in's plain-text condition symbols (format %x), by icon name.
    readonly property var symbolIcons: ({
        "o": "weather-clear",
        "m": "weather-cloudy", "mm": "weather-cloudy", "mmm": "weather-cloudy",
        "=": "weather-fog",
        "/": "weather-rain", "//": "weather-rain", "///": "weather-rain", ".": "weather-rain",
        "x": "weather-rain", "x/": "weather-rain",
        "*": "weather-snow", "**": "weather-snow", "*/": "weather-snow", "*/*": "weather-snow",
        "!/": "weather-storm", "/!/": "weather-storm", "*!*": "weather-storm"
    })

    function secondsOfDay(clock) {
        var parts = String(clock || "").split(":");
        if (parts.length < 2)
            return -1;
        return Number(parts[0]) * 3600 + Number(parts[1]) * 60 + Number(parts[2] || 0);
    }

    // Parses the "symbol|temperature|sunrise|sunset|condition" answer, or returns null
    // when wttr.in answered with an error. A clear sky outside sunrise..sunset shows
    // the night icon.
    function parse(text) {
        var fields = String(text || "").trim().split("|");
        if (fields.length < 5 || !/\d/.test(fields[1]))
            return null;
        var icon = root.symbolIcons[fields[0].trim()] || "weather-cloudy";
        var now = new Date();
        var seconds = now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds();
        var sunrise = root.secondsOfDay(fields[2]);
        var sunset = root.secondsOfDay(fields[3]);
        if (icon === "weather-clear" && sunrise >= 0 && sunset >= 0
                && (seconds < sunrise || seconds >= sunset))
            icon = "weather-night";
        return {
            icon: icon,
            temperature: fields[1].trim().replace(/^\+/, ""),
            condition: fields[4].trim()
        };
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
            root.status = "loading";
            root.fetchWeather();
        } else {
            root.fetchQueued = false;
            retryTimer.stop();
            weatherProc.running = false;
            root.status = "";
        }
    }

    function fetchWeather() {
        if (!root.enabled)
            return;
        if (!weatherProc.running) {
            const loc = String(root.location || "").trim();
            const url = "https://wttr.in/" + (loc !== "" ? encodeURIComponent(loc) : "") + "?format=%x|%t|%S|%s|%C";
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

        onRunningChanged: {
            if (running) {
                weatherProc.output = "";
            }
        }

        stdout: SplitParser {
            onRead: function(data) {
                weatherProc.output += data;
            }
        }

        onExited: function(exitCode) {
            var text = weatherProc.output.trim();
            weatherProc.output = "";
            var weather = exitCode === 0 ? root.parse(text) : null;
            if (weather) {
                root.iconName = weather.icon;
                root.temperature = weather.temperature;
                root.condition = weather.condition;
                root.status = "ready";
            } else if (root.status !== "ready") {
                // Keep the last reading through a failed refresh.
                root.status = "offline";
            }
            if (!weather && root.enabled)
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
