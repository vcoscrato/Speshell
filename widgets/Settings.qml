pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root

    property bool relaunching: false
    property bool presented: false
    property string activePage: ""
    property string weatherLocationDraft: ""

    readonly property var settingsConfig: Services.ConfigService.config || ({})
    readonly property var launcherConfig: root.settingsConfig.launcher || ({})
    readonly property string pageTitle: {
        if (root.activePage === "appearance") return "Appearance";
        if (root.activePage === "audio") return "Audio";
        if (root.activePage === "launcher") return "Launcher";
        if (root.activePage === "integrations") return "Integrations";
        if (root.activePage === "notifications") return "Notifications";
        if (root.activePage === "advanced") return "Advanced";
        return "Settings";
    }
    readonly property var categories: [
        { id: "appearance", label: "Appearance", detail: "Theme & panel geometry" },
        { id: "audio", label: "Audio", detail: "Panel & volume behavior" },
        { id: "launcher", label: "Launcher", detail: "Size & search" },
        { id: "integrations", label: "Integrations", detail: "Weather & hardware" },
        { id: "notifications", label: "Notifications", detail: "Toast behavior" },
        { id: "advanced", label: "Advanced", detail: "Config file & runtime" }
    ]
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
    readonly property var panelWidthOptions: [
        { value: 360, label: "Compact · 360 px" },
        { value: 420, label: "Default · 420 px" },
        { value: 520, label: "Wide · 520 px" },
        { value: 640, label: "Extra Wide · 640 px" }
    ]
    readonly property var panelMarginOptions: [
        { value: 0, label: "None" },
        { value: 8, label: "8 px" },
        { value: 16, label: "16 px" },
        { value: 24, label: "24 px" },
        { value: 32, label: "32 px" }
    ]
    readonly property var audioModeOptions: [
        { value: "combined", label: "Speaker + Mic" },
        { value: "separate", label: "Separate Icons" }
    ]
    readonly property var scrollStepOptions: [
        { value: 2, label: "Precise · 2%" },
        { value: 5, label: "Standard · 5%" },
        { value: 10, label: "Fast · 10%" }
    ]
    readonly property var launcherRowOptions: [
        { value: 3, label: "3 Rows" },
        { value: 5, label: "5 Rows" },
        { value: 7, label: "7 Rows" },
        { value: 10, label: "10 Rows" }
    ]
    readonly property var launcherWidthOptions: [
        { value: 420, label: "Compact · 420 px" },
        { value: 540, label: "Default · 540 px" },
        { value: 680, label: "Wide · 680 px" },
        { value: 800, label: "Extra Wide · 800 px" }
    ]
    readonly property var searchEngineOptions: [
        { value: "https://duckduckgo.com/?q={query}", label: "DuckDuckGo" },
        { value: "https://www.google.com/search?q={query}", label: "Google" },
        { value: "https://searx.be/search?q={query}", label: "SearXNG" },
        { value: "https://www.bing.com/search?q={query}", label: "Bing" }
    ]
    readonly property var notificationOptions: [
        { value: 1, label: "1 Toast" },
        { value: 3, label: "3 Toasts" },
        { value: 5, label: "5 Toasts" },
        { value: 10, label: "10 Toasts" },
        { value: -1, label: "Unlimited" }
    ]
    readonly property var backlightOptions: root.buildBacklightOptions(Services.FeatureSupport.backlightDevices)

    title: root.pageTitle
    iconName: "config"

    onPresentedChanged: if (!root.presented) root.activePage = ""

    headerActions: Row {
        spacing: ThemeModule.Theme.spacingSmall

        Components.InlineActionChip {
            visible: root.activePage !== ""
            text: "Back"
            iconName: "back"
            tone: "neutral"
            onActivated: root.activePage = ""
        }
    }

    function buildBacklightOptions(devices) {
        var options = [{ value: "", label: "Auto" }];
        var detected = devices || [];
        for (var i = 0; i < detected.length; i++)
            options.push({ value: detected[i], label: detected[i] });
        return options;
    }

    function openPage(page) {
        root.activePage = page;
        if (page === "integrations")
            root.weatherLocationDraft = String(root.settingsConfig.weatherLocation || "");
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
        spacing: ThemeModule.Theme.spacingSmall

        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: root.activePage === ""

            Repeater {
                model: root.categories

                delegate: Components.SelectRow {
                    required property var modelData

                    label: modelData.label
                    value: modelData.detail
                    valueMaxWidth: 220
                    indicatorIconName: "chevron-right"
                    onActivated: root.openPage(modelData.id)
                }
            }
        }

        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: root.activePage === "appearance"

            Components.SelectMenuRow {
                enabled: !Services.ConfigService.savingConfig
                label: "Theme"
                options: root.themeOptions
                currentValue: ThemeModule.Theme.paletteName
                onValueSelected: function(value) { Services.ConfigService.setColorScheme(value); }
            }

            Components.SelectMenuRow {
                enabled: !Services.ConfigService.savingConfig
                label: "Panel Width"
                options: root.panelWidthOptions
                currentValue: root.settingsConfig.panelWidth !== undefined ? root.settingsConfig.panelWidth : 420
                fallbackLabel: currentValue + " px · Custom"
                onValueSelected: function(value) { Services.ConfigService.setPanelWidth(value); }
            }

            Components.SelectMenuRow {
                enabled: !Services.ConfigService.savingConfig
                label: "Panel Margin"
                options: root.panelMarginOptions
                currentValue: root.settingsConfig.panelMargin !== undefined ? root.settingsConfig.panelMargin : 16
                fallbackLabel: currentValue + " px · Custom"
                onValueSelected: function(value) { Services.ConfigService.setPanelMargin(value); }
            }
        }

        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: root.activePage === "audio"

            Components.SelectMenuRow {
                enabled: !Services.ConfigService.savingConfig
                label: "Audio Panel"
                options: root.audioModeOptions
                currentValue: root.settingsConfig.audioPanelMode || "combined"
                onValueSelected: function(value) { Services.ConfigService.setAudioPanelMode(value); }
            }

            Components.SelectMenuRow {
                enabled: !Services.ConfigService.savingConfig
                label: "Volume Scroll"
                options: root.scrollStepOptions
                currentValue: root.settingsConfig.audioScrollStep !== undefined ? root.settingsConfig.audioScrollStep : 5
                fallbackLabel: currentValue + "% · Custom"
                onValueSelected: function(value) { Services.ConfigService.setAudioScrollStep(value); }
            }
        }

        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: root.activePage === "launcher"

            Components.SelectMenuRow {
                enabled: !Services.ConfigService.savingConfig
                label: "Visible Rows"
                options: root.launcherRowOptions
                currentValue: root.launcherConfig.visibleRows !== undefined ? root.launcherConfig.visibleRows : 5
                fallbackLabel: currentValue + " Rows · Custom"
                onValueSelected: function(value) { Services.ConfigService.setLauncherRows(value); }
            }

            Components.SelectMenuRow {
                enabled: !Services.ConfigService.savingConfig
                label: "Launcher Width"
                options: root.launcherWidthOptions
                currentValue: root.launcherConfig.width !== undefined ? root.launcherConfig.width : 540
                fallbackLabel: currentValue + " px · Custom"
                onValueSelected: function(value) { Services.ConfigService.setLauncherWidth(value); }
            }

            Components.SelectMenuRow {
                enabled: !Services.ConfigService.savingConfig
                label: "Search Engine"
                options: root.searchEngineOptions
                currentValue: root.launcherConfig.searchUrl || "https://duckduckgo.com/?q={query}"
                fallbackLabel: "Custom INI value"
                onValueSelected: function(value) { Services.ConfigService.setLauncherSearchUrl(value); }
            }
        }

        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: root.activePage === "integrations"

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
                    onToggled: function(newState) { Services.ConfigService.setWeatherEnabled(newState); }
                }
            }

            Row {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Rectangle {
                    width: parent.width - locationApply.width - parent.spacing
                    height: 32
                    radius: ThemeModule.Theme.borderRadiusSmall
                    color: ThemeModule.Theme.card
                    border.width: locationInput.activeFocus ? 2 : ThemeModule.Theme.borderWidth
                    border.color: locationInput.activeFocus ? ThemeModule.Theme.accent : ThemeModule.Theme.cardHover

                    TextInput {
                        id: locationInput
                        anchors.fill: parent
                        anchors.leftMargin: ThemeModule.Theme.spacingSmall
                        anchors.rightMargin: ThemeModule.Theme.spacingSmall
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.weatherLocationDraft
                        color: ThemeModule.Theme.text
                        selectionColor: ThemeModule.Theme.accent
                        selectedTextColor: ThemeModule.Theme.bg
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        clip: true
                        enabled: !Services.ConfigService.savingConfig
                        Accessible.name: "Weather location"
                        onTextEdited: root.weatherLocationDraft = text
                        onAccepted: Services.ConfigService.setWeatherLocation(root.weatherLocationDraft)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: locationInput.text === "" && !locationInput.activeFocus
                            text: "Automatic location"
                            font: locationInput.font
                            color: ThemeModule.Theme.overlay
                        }
                    }
                }

                Components.ActionButton {
                    id: locationApply
                    width: 78
                    label: "Apply"
                    iconName: "check"
                    enabled: !Services.ConfigService.savingConfig
                        && root.weatherLocationDraft !== String(root.settingsConfig.weatherLocation || "")
                    onActivated: Services.ConfigService.setWeatherLocation(root.weatherLocationDraft)
                }
            }

            Components.SelectMenuRow {
                enabled: !Services.ConfigService.savingConfig
                label: "Backlight"
                options: root.backlightOptions
                currentValue: root.settingsConfig.backlightDevice || ""
                fallbackLabel: currentValue + " · Missing"
                onValueSelected: function(value) { Services.ConfigService.setBacklightDevice(value); }
            }

            Repeater {
                model: Services.FeatureSupport.issues

                delegate: Rectangle {
                    id: issueRow

                    required property var modelData

                    width: parent.width
                    implicitHeight: issueText.implicitHeight + ThemeModule.Theme.spacingSmall * 2
                    radius: ThemeModule.Theme.borderRadiusSmall
                    color: Qt.rgba(ThemeModule.Theme.warning.r, ThemeModule.Theme.warning.g, ThemeModule.Theme.warning.b, 0.09)
                    border.width: ThemeModule.Theme.borderWidth
                    border.color: Qt.rgba(ThemeModule.Theme.warning.r, ThemeModule.Theme.warning.g, ThemeModule.Theme.warning.b, 0.38)

                    Text {
                        id: issueText
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: ThemeModule.Theme.spacingSmall
                        anchors.rightMargin: ThemeModule.Theme.spacingSmall
                        text: issueRow.modelData.detail
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.warning
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Text {
                visible: Services.FeatureSupport.issuesReady && Services.FeatureSupport.issues.length === 0
                width: parent.width
                text: "Configured integrations are ready."
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.success
                wrapMode: Text.WordWrap
            }
        }

        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: root.activePage === "notifications"

            Components.SelectMenuRow {
                enabled: !Services.ConfigService.savingConfig
                label: "Visible Toasts"
                options: root.notificationOptions
                currentValue: root.settingsConfig.maxVisibleNotification !== undefined
                    ? root.settingsConfig.maxVisibleNotification
                    : 3
                fallbackLabel: currentValue === -1 ? "Unlimited" : currentValue + " Toasts · Custom"
                onValueSelected: function(value) { Services.ConfigService.setMaxVisibleNotification(value); }
            }
        }

        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: root.activePage === "advanced"

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

            Text {
                width: parent.width
                text: "Workspace, audio mappings, custom bangs, search URLs, and power arguments remain in the INI file."
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.overlay
                wrapMode: Text.WordWrap
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
