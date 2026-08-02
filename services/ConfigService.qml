pragma Singleton
// qmllint disable signal-handler-parameters

import QtQuick
import Quickshell
import Quickshell.Io
import "../core/Config.js" as Config

Singleton {
    id: root

    readonly property string bundledExamplePath: Qt.resolvedUrl("../config.example.jsonc").toString().replace(/^file:\/\//, "")
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
                + "config_file=\"$config_dir/config.jsonc\"; "
                + "mkdir -p \"$config_root\" \"$data_root\" || exit 20; "
                + "mkdir -p \"$config_dir\" \"$data_dir\" || exit 20; "
                + "printf '%s\\n%s\\n' \"$config_dir\" \"$data_dir\"; "
                + "if [ -e \"$config_file\" ] || [ -L \"$config_file\" ]; then "
                + "cat \"$config_file\" || exit 21; "
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
            root.configPath = configDir + "/config.jsonc";
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

        var jsonc = output.substring(nl2 + 1);
        var result = Config.parseAndValidate(jsonc);
        if (!result.ok) {
            root.config = null;
            root.errors = result.errors;
            root.status = "invalid";
            return;
        }

        root.errors = [];
        root.sourceText = jsonc;
        root.config = result.config;
        root.status = "valid";
    }

    function withColorScheme(configValue, colorScheme) {
        var result = ({});
        var keys = Object.keys(configValue || ({}));
        for (var i = 0; i < keys.length; i++)
            result[keys[i]] = configValue[keys[i]];
        result.colorScheme = colorScheme;
        return result;
    }

    function stringEnd(text, start) {
        for (var i = start + 1; i < text.length; i++) {
            if (text[i] === "\\") {
                i++;
                continue;
            }
            if (text[i] === "\"")
                return i;
        }
        return -1;
    }

    function topLevelStringPropertyRange(text, propertyName) {
        var stripped = Config.stripComments(String(text || ""));
        var expectedName = JSON.stringify(propertyName);
        var depth = 0;
        for (var i = 0; i < stripped.length; i++) {
            if (stripped[i] === "\"") {
                var nameEnd = root.stringEnd(stripped, i);
                if (nameEnd < 0)
                    return null;
                if (depth === 1 && stripped.substring(i, nameEnd + 1) === expectedName) {
                    var cursor = nameEnd + 1;
                    while (/\s/.test(stripped[cursor] || "")) cursor++;
                    if (stripped[cursor] === ":") cursor++;
                    while (/\s/.test(stripped[cursor] || "")) cursor++;
                    if (stripped[cursor] === "\"") {
                        var valueEnd = root.stringEnd(stripped, cursor);
                        return valueEnd >= 0 ? { start: cursor, end: valueEnd + 1 } : null;
                    }
                }
                i = nameEnd;
            } else if (stripped[i] === "{") {
                depth++;
            } else if (stripped[i] === "}") {
                depth--;
            }
        }
        return null;
    }

    function replaceColorScheme(text, colorScheme) {
        var source = String(text || "");
        var propertyRange = root.topLevelStringPropertyRange(source, "colorScheme");
        if (propertyRange)
            return source.substring(0, propertyRange.start)
                + JSON.stringify(colorScheme)
                + source.substring(propertyRange.end);

        var rootStart = Config.stripComments(source).indexOf("{");
        if (rootStart < 0)
            return "";
        return source.substring(0, rootStart + 1)
            + "\n    \"colorScheme\": " + JSON.stringify(colorScheme) + ","
            + source.substring(rootStart + 1);
    }

    function setColorScheme(colorScheme) {
        var requested = String(colorScheme || "");
        if (!root.valid || root.savingConfig || !Config.isPaletteName(requested))
            return false;
        if (root.config.colorScheme === requested)
            return true;

        var currentText = configFile.text();
        if (String(currentText || "").trim() === "")
            currentText = root.sourceText;
        var updatedText = root.replaceColorScheme(currentText, requested);
        var parsed = Config.parseAndValidate(updatedText);
        if (!parsed.ok) {
            root.operationFailed = true;
            root.operationMessage = "The config changed on disk and must be fixed before saving the theme.";
            return false;
        }

        root.previousConfig = root.config;
        root.pendingConfig = parsed.config;
        root.writeText = updatedText;
        root.savingConfig = true;
        root.operationFailed = false;
        root.operationMessage = "";

        // Apply immediately; a failed write restores the previous config.
        root.config = root.withColorScheme(root.config, requested);
        configFile.setText(root.writeText);
        return true;
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
            root.operationMessage = "Could not save the theme to the config file.";
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
            "File: " + (root.configPath || "~/.config/speshell/config.jsonc"),
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
            : "path=\"${XDG_CONFIG_HOME:-$HOME/.config}/speshell/config.jsonc\"; ";
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
        atomicWrites: false
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
