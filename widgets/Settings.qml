import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root

    property bool relaunching: false
    readonly property var themeOptions: [
        { name: "gruvbox", label: "Gruvbox" },
        { name: "catppuccin-mocha", label: "Catppuccin Mocha" },
        { name: "catppuccin-macchiato", label: "Catppuccin Macchiato" },
        { name: "catppuccin-frappe", label: "Catppuccin Frappé" },
        { name: "catppuccin-latte", label: "Catppuccin Latte" },
        { name: "nord", label: "Nord" },
        { name: "dracula", label: "Dracula" },
        { name: "tokyo-night", label: "Tokyo Night" },
        { name: "rose-pine", label: "Rosé Pine" },
        { name: "solarized-dark", label: "Solarized Dark" },
        { name: "everforest", label: "Everforest" }
    ]

    function themeLabel(themeName) {
        for (var i = 0; i < root.themeOptions.length; i++) {
            if (root.themeOptions[i].name === themeName)
                return root.themeOptions[i].label;
        }
        return themeName;
    }

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
        spacing: ThemeModule.Theme.spacingMedium

        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall

            Text {
                text: "Appearance"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                font.bold: true
                color: ThemeModule.Theme.text
            }

            Components.SelectRow {
                id: themeRow

                enabled: !Services.ConfigService.savingConfig
                label: "Theme"
                value: root.themeLabel(ThemeModule.Theme.paletteName)
                valueMaxWidth: 210
                onActivated: themeMenu.open()

                Controls.Menu {
                    id: themeMenu
                    y: themeRow.height
                    width: themeRow.width

                    Instantiator {
                        model: root.themeOptions

                        delegate: Controls.MenuItem {
                            required property var modelData

                            text: modelData.label
                            checkable: true
                            checked: ThemeModule.Theme.paletteName === modelData.name
                            enabled: !Services.ConfigService.savingConfig
                            onTriggered: Services.ConfigService.setColorScheme(modelData.name)
                        }

                        onObjectAdded: function(index, object) {
                            themeMenu.insertItem(index, object);
                        }
                        onObjectRemoved: function(index, object) {
                            themeMenu.removeItem(object);
                        }
                    }
                }
            }
        }

        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall

            Text {
                text: "Configuration"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                font.bold: true
                color: ThemeModule.Theme.text
            }

            Text {
                width: parent.width
                text: Services.ConfigService.configPath !== ""
                    ? Services.ConfigService.configPath
                    : "~/.config/speshell/config.jsonc"
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
            wrapMode: Text.WordWrap
        }
    }
}
