import QtQuick
import Quickshell
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root

    property bool relaunching: false

    readonly property var settingsConfig: Services.ConfigService.config || ({})
    readonly property var launcherConfig: root.settingsConfig.launcher || ({})
    readonly property var themeOptions: [
        { value: "gruvbox", label: "Gruvbox" },
        { value: "catppuccin-mocha", label: "Catppuccin Mocha" },
        { value: "catppuccin-macchiato", label: "Catppuccin Macchiato" },
        { value: "catppuccin-frappe", label: "Catppuccin Frappé" },
        { value: "catppuccin-latte", label: "Catppuccin Latte" },
        { value: "nord", label: "Nord" },
        { value: "dracula", label: "Dracula" },
        { value: "tokyo-night", label: "Tokyo Night" },
        { value: "rose-pine", label: "Rosé Pine" },
        { value: "solarized-dark", label: "Solarized Dark" },
        { value: "everforest", label: "Everforest" }
    ]
    readonly property var audioModeOptions: [
        { value: "combined", label: "Speaker + Mic" },
        { value: "separate", label: "Separate Icons" }
    ]
    readonly property var scrollStepOptions: [
        { value: 2, label: "Precise (2%)" },
        { value: 5, label: "Standard (5%)" },
        { value: 10, label: "Fast (10%)" }
    ]
    readonly property var notificationOptions: [
        { value: 1, label: "1 Toast" },
        { value: 3, label: "3 Toasts" },
        { value: 5, label: "5 Toasts" },
        { value: 10, label: "10 Toasts" },
        { value: -1, label: "Unlimited" }
    ]
    readonly property var launcherRowOptions: [
        { value: 3, label: "3 Rows" },
        { value: 5, label: "5 Rows" },
        { value: 7, label: "7 Rows" },
        { value: 10, label: "10 Rows" }
    ]
    readonly property var searchEngineOptions: [
        { value: "https://duckduckgo.com/?q={query}", label: "DuckDuckGo" },
        { value: "https://www.google.com/search?q={query}", label: "Google" },
        { value: "https://searx.be/search?q={query}", label: "SearXNG" },
        { value: "https://www.bing.com/search?q={query}", label: "Bing" }
    ]

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
    }

    function relaunch() {
        if (root.relaunching || Services.ConfigService.savingConfig)
            return;

        root.relaunching = true;
        Services.NotesService.flush(true);

        var shellPath = Quickshell.shellDir !== ""
            ? Quickshell.shellDir
            : Quickshell.shellRoot;
        var command = "launcher=$(readlink -f /proc/" + Quickshell.processId + "/exe 2>/dev/null || command -v quickshell || printf quickshell); "
            + "while kill -0 " + Quickshell.processId + " 2>/dev/null; do sleep 0.05; done; "
            + "sleep 0.1; "
            + "exec \"$launcher\" --daemonize";
        if (shellPath !== "")
            command += " -p " + root.shellQuote(shellPath);

        Quickshell.execDetached(["sh", "-c", command]);
        Qt.quit();
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Components.SelectMenuRow {
            enabled: !Services.ConfigService.savingConfig
            label: "Theme"
            options: root.themeOptions
            currentValue: ThemeModule.Theme.paletteName
            onValueSelected: function(value) {
                Services.ConfigService.setColorScheme(value);
            }
        }

        Components.SelectMenuRow {
            enabled: !Services.ConfigService.savingConfig
            label: "Audio Panel"
            options: root.audioModeOptions
            currentValue: root.settingsConfig.audioPanelMode || "combined"
            onValueSelected: function(value) {
                Services.ConfigService.setAudioPanelMode(value);
            }
        }

        Components.SelectMenuRow {
            enabled: !Services.ConfigService.savingConfig
            label: "Volume Scroll"
            options: root.scrollStepOptions
            currentValue: root.settingsConfig.audioScrollStep !== undefined
                ? root.settingsConfig.audioScrollStep
                : 5
            fallbackLabel: currentValue + "%"
            onValueSelected: function(value) {
                Services.ConfigService.setAudioScrollStep(value);
            }
        }

        Components.SelectMenuRow {
            enabled: !Services.ConfigService.savingConfig
            label: "Toasts"
            options: root.notificationOptions
            currentValue: root.settingsConfig.maxVisibleNotification !== undefined
                ? root.settingsConfig.maxVisibleNotification
                : 3
            fallbackLabel: currentValue === -1 ? "Unlimited" : currentValue + " Toasts"
            onValueSelected: function(value) {
                Services.ConfigService.setMaxVisibleNotification(value);
            }
        }

        Components.SelectMenuRow {
            enabled: !Services.ConfigService.savingConfig
            label: "Launcher Height"
            options: root.launcherRowOptions
            currentValue: root.launcherConfig.visibleRows !== undefined
                ? root.launcherConfig.visibleRows
                : 5
            fallbackLabel: currentValue + " Rows"
            onValueSelected: function(value) {
                Services.ConfigService.setLauncherRows(value);
            }
        }

        Components.SelectMenuRow {
            enabled: !Services.ConfigService.savingConfig
            label: "Search Engine"
            options: root.searchEngineOptions
            currentValue: root.launcherConfig.searchUrl || "https://duckduckgo.com/?q={query}"
            fallbackLabel: "Custom"
            onValueSelected: function(value) {
                Services.ConfigService.setProperty("Launcher", "searchUrl", value);
            }
        }

        Item {
            width: parent.width
            height: 32

            Text {
                text: "Weather"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext
                anchors.left: parent.left
                anchors.leftMargin: ThemeModule.Theme.spacingSmall
                anchors.verticalCenter: parent.verticalCenter
            }

            Components.ToggleSwitch {
                anchors.right: parent.right
                anchors.rightMargin: ThemeModule.Theme.spacingSmall
                anchors.verticalCenter: parent.verticalCenter
                checked: root.settingsConfig.weatherEnabled || false
                enabled: !Services.ConfigService.savingConfig
                tooltipText: checked ? "Disable weather" : "Enable weather"
                onToggled: function(newState) {
                    Services.ConfigService.setWeatherEnabled(newState);
                }
            }
        }

        Item {
            width: 1
            height: ThemeModule.Theme.spacingSmall
        }

        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall

            Text {
                width: parent.width
                text: Services.ConfigService.configPath !== ""
                    ? Services.ConfigService.configPath
                    : "~/.config/speshell/config.ini"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext
                wrapMode: Text.WrapAnywhere
            }

            Row {
                id: actionsRow

                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall
                readonly property real buttonWidth: (width - spacing * 2) / 3

                Components.ActionButton {
                    width: actionsRow.buttonWidth
                    label: "Open"
                    iconName: "folder-open"
                    enabled: !Services.ConfigService.savingConfig
                    onActivated: Services.ConfigService.openConfig()
                }

                Components.ActionButton {
                    width: actionsRow.buttonWidth
                    label: Services.ConfigService.loading ? "Loading" : "Reload"
                    iconName: "refresh"
                    enabled: !Services.ConfigService.loading && !Services.ConfigService.savingConfig
                    onActivated: Services.ConfigService.load()
                }

                Components.ActionButton {
                    width: actionsRow.buttonWidth
                    label: root.relaunching ? "Starting" : "Relaunch"
                    iconName: "restart"
                    toneColor: ThemeModule.Theme.warning
                    enabled: !root.relaunching && !Services.ConfigService.savingConfig
                    onActivated: root.relaunch()
                }
            }
        }

        Text {
            visible: Services.ConfigService.operationFailed
                && Services.ConfigService.operationMessage !== ""
            width: parent.width
            text: Services.ConfigService.operationMessage
            color: ThemeModule.Theme.error
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            wrapMode: Text.WrapAnywhere
        }
    }
}
