pragma Singleton
// qmllint disable signal-handler-parameters

import QtQuick
import Quickshell
import Quickshell.Io
import "../core/Config.js" as Config

Singleton {
    id: root

    readonly property string bundledExamplePath: Qt.resolvedUrl("../config.example.ini").toString().replace(/^file:\/\//, "")
    property string status: "idle"
    property var config: null
    property var errors: []
    property string configPath: ""
    property string dataDir: ""
    property bool reloadQueued: false
    property string operationMessage: ""
    property bool operationFailed: false
    property string sourceText: ""
    property string writeText: ""
    property var pendingConfig: null
    property var previousConfig: null
    property bool savingConfig: false
    readonly property bool valid: root.status === "valid" && root.config !== null
    readonly property bool invalid: root.status === "invalid"
    readonly property bool loading: root.status === "loading"
    readonly property string errorReport: root.buildErrorReport()

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
    }

    function load() {
        if (configLoadProc.running) {
            root.reloadQueued = true;
            return;
        }

        root.reloadQueued = false;
        root.status = "loading";
        root.config = null;
        root.errors = [];
        root.operationMessage = "";
        root.operationFailed = false;
        configLoadProc.command = [
            "sh", "-c",
            "config_root=\"${XDG_CONFIG_HOME:-$HOME/.config}\"; "
                + "data_root=\"${XDG_DATA_HOME:-$HOME/.local/share}\"; "
                + "config_dir=\"$config_root/speshell\"; "
                + "data_dir=\"$data_root/speshell\"; "
                + "ini_file=\"$config_dir/config.ini\"; "
                + "mkdir -p \"$config_root\" \"$data_root\" || exit 20; "
                + "mkdir -p \"$config_dir\" \"$data_dir\" || exit 20; "
                + "printf '%s\\n%s\\n' \"$config_dir\" \"$data_dir\"; "
                + "if [ ! -e \"$ini_file\" ] && [ ! -L \"$ini_file\" ]; then "
                + "cp " + root.shellQuote(root.bundledExamplePath) + " \"$ini_file\" 2>/dev/null || true; "
                + "fi; "
                + "if [ -e \"$ini_file\" ] || [ -L \"$ini_file\" ]; then "
                + "cat \"$ini_file\" || exit 21; "
                + "else cat " + root.shellQuote(root.bundledExamplePath) + " || exit 22; fi"
        ];
        configLoadProc.running = true;
    }

    function failLoader(message) {
        root.config = null;
        root.errors = [{ kind: "io", path: root.configPath || "$", line: 0, column: 0, message: message }];
        root.status = "invalid";
    }

    function applyLoaderOutput(text, exitCode, stderrText) {
        var output = String(text || "");
        var nl1 = output.indexOf("\n");
        var nl2 = output.indexOf("\n", nl1 + 1);
        if (nl1 >= 0 && nl2 >= 0) {
            var configDir = output.substring(0, nl1);
            root.dataDir = output.substring(nl1 + 1, nl2);
            root.configPath = configDir + "/config.ini";
        }

        if (exitCode !== 0) {
            var detail = String(stderrText || "").trim();
            root.failLoader(detail !== "" ? detail : "Could not read the configuration file (loader exit " + exitCode + ").");
            return;
        }
        if (nl1 < 0 || nl2 < 0) {
            root.failLoader("The configuration loader returned an unexpected response.");
            return;
        }

        var iniContent = output.substring(nl2 + 1);
        var result = Config.parseAndValidate(iniContent);
        if (!result.ok) {
            root.config = null;
            root.errors = result.errors;
            root.status = "invalid";
            return;
        }

        root.errors = [];
        root.sourceText = iniContent;
        root.config = result.config;
        root.status = "valid";
    }

    function setProperty(section, key, value) {
        if (!root.valid || root.savingConfig)
            return false;

        var currentText = root.sourceText;
        if (String(currentText || "").trim() === "")
            currentText = configFile.text();

        var updatedText = Config.setIniProperty(currentText, section, key, value);
        var parsed = Config.parseAndValidate(updatedText);
        if (!parsed.ok) {
            root.operationFailed = true;
            root.operationMessage = "Could not apply setting: " + (parsed.errors[0] ? parsed.errors[0].message : "invalid configuration");
            return false;
        }
        if (updatedText === currentText)
            return true;

        root.previousConfig = root.config;
        root.pendingConfig = parsed.config;
        root.writeText = updatedText;
        root.savingConfig = true;
        root.operationFailed = false;
        root.operationMessage = "";

        // Optimistically apply new config state
        root.config = parsed.config;

        configFile.setText(root.writeText);
        return true;
    }

    function setColorScheme(colorScheme) {
        if (!Config.isPaletteName(colorScheme)) return false;
        return setProperty("Appearance", "colorScheme", colorScheme);
    }

    function setPanelWidth(width) {
        return setProperty("Appearance", "panelWidth", width);
    }

    function setPanelMargin(margin) {
        return setProperty("Appearance", "panelMargin", margin);
    }

    function setAudioPanelMode(mode) {
        if (mode !== "combined" && mode !== "separate") return false;
        return setProperty("Audio", "panelMode", mode);
    }

    function setAudioScrollStep(step) {
        return setProperty("Audio", "scrollStep", step);
    }

    function setWeatherEnabled(enabled) {
        return setProperty("Weather", "enabled", enabled ? "true" : "false");
    }

    function setWeatherLocation(location) {
        return setProperty("Weather", "location", location);
    }

    function setMaxVisibleNotification(count) {
        return setProperty("Notifications", "maxVisible", count);
    }

    function setLauncherRows(rows) {
        return setProperty("Launcher", "visibleRows", rows);
    }

    function setLauncherWidth(width) {
        return setProperty("Launcher", "width", width);
    }

    function finishConfigWrite(succeeded) {
        var nextConfig = root.pendingConfig;
        var oldConfig = root.previousConfig;
        if (succeeded)
            root.sourceText = root.writeText;

        root.writeText = "";
        root.pendingConfig = null;
        root.previousConfig = null;
        root.savingConfig = false;

        if (succeeded) {
            root.config = nextConfig;
            root.operationFailed = false;
            root.operationMessage = "";
        } else {
            root.config = oldConfig;
            root.operationFailed = true;
            root.operationMessage = "Could not save settings to config.ini.";
        }
    }

    function diagnosticText(diagnostic) {
        var location = "";
        if (diagnostic.line > 0) {
            location = "line " + diagnostic.line;
            if (diagnostic.column > 0)
                location += ", column " + diagnostic.column;
        } else if (diagnostic.path && diagnostic.path !== "$") {
            location = diagnostic.path;
        }
        return (location !== "" ? location + ": " : "") + String(diagnostic.message || "Invalid configuration.");
    }

    function buildErrorReport() {
        if (!root.invalid || root.errors.length === 0)
            return "";
        var lines = [
            "Speshell configuration error",
            "Version: " + SystemState.appVersion,
            "File: " + (root.configPath || "~/.config/speshell/config.ini"),
            ""
        ];
        for (var i = 0; i < root.errors.length; i++)
            lines.push((i + 1) + ". " + root.diagnosticText(root.errors[i]));
        return lines.join("\n");
    }

    function openConfig() {
        if (openConfigProc.running)
            return;
        var pathAssignment = root.configPath !== ""
            ? "path=" + root.shellQuote(root.configPath) + "; "
            : "path=\"${XDG_CONFIG_HOME:-$HOME/.config}/speshell/config.ini\"; ";
        root.operationMessage = "";
        root.operationFailed = false;
        openConfigProc.command = [
            "sh", "-c",
            pathAssignment
                + "if [ -n \"${VISUAL:-}\" ]; then exec \"$VISUAL\" \"$path\"; "
                + "elif [ -n \"${EDITOR:-}\" ]; then exec \"$EDITOR\" \"$path\"; "
                + "else exec xdg-open \"$path\"; fi"
        ];
        openConfigProc.running = true;
    }

    function copyErrorReport() {
        if (copyReportProc.running || root.errorReport === "")
            return;
        root.operationMessage = "";
        root.operationFailed = false;
        copyReportProc.command = [
            "sh", "-c",
            "printf '%s' " + root.shellQuote(root.errorReport) + " | wl-copy"
        ];
        copyReportProc.running = true;
    }

    Process {
        id: configLoadProc
        running: false
        stdout: StdioCollector { id: configOutput }
        stderr: StdioCollector { id: configErrorOutput }
        onExited: function(exitCode) {
            root.applyLoaderOutput(configOutput.text, exitCode, configErrorOutput.text);
            if (root.reloadQueued) {
                root.reloadQueued = false;
                Qt.callLater(root.load);
            }
        }
    }

    FileView {
        id: configFile
        path: root.configPath
        blockLoading: true
        atomicWrites: true
        printErrors: false
        onSaved: root.finishConfigWrite(true)
        onSaveFailed: root.finishConfigWrite(false)
    }

    Process {
        id: openConfigProc
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.operationFailed = true;
                root.operationMessage = "Could not open the configuration file.";
            }
        }
    }

    Process {
        id: copyReportProc
        running: false
        onExited: function(exitCode) {
            root.operationFailed = exitCode !== 0;
            root.operationMessage = exitCode === 0
                ? "Error report copied."
                : "Could not copy the report; select the text manually.";
        }
    }
}
