pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string appVersion: "Unknown"
    readonly property string appDir: Qt.resolvedUrl("..").toString().replace(/^file:\/\//, "")

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
    }

    Process {
        id: appVersionProc
        running: false

        stdout: StdioCollector { id: appVersionOutput }

        onRunningChanged: if (!running) {
            var version = (appVersionOutput.text || "").trim();
            root.appVersion = version !== "" ? version : "Unknown";
        }
    }

    Component.onCompleted: {
        appVersionProc.command = [
            "sh", "-c",
            "app_dir=" + root.shellQuote(root.appDir) + "; "
                + "if command -v git >/dev/null 2>&1 "
                + "&& git -C \"$app_dir\" rev-parse --is-inside-work-tree >/dev/null 2>&1; then "
                + "printf 'r%s.g%s\\n' "
                + "\"$(git -C \"$app_dir\" rev-list --count HEAD)\" "
                + "\"$(git -C \"$app_dir\" rev-parse --short=7 HEAD)\"; "
                + "elif package_info=$(pacman -Q speshell-git 2>/dev/null || pacman -Q speshell 2>/dev/null); then "
                + "set -- $package_info; version=$2; printf '%s\\n' \"${version%-*}\"; "
                + "else printf 'Unknown\\n'; fi"
        ];
        appVersionProc.running = true;
    }
}
