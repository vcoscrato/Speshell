pragma ComponentBehavior: Bound
import QtQuick
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root

    property string activePage: "general"
    // The location being typed; null shows the saved one. Deriving the field from both,
    // rather than copying the saved value in on change, keeps `dirty` free of a loop.
    property var weatherLocationEdit: null

    readonly property var settingsConfig: Services.ConfigService.config || ({})
    readonly property var launcherConfig: root.settingsConfig.launcher || ({})
    readonly property var barConfig: root.settingsConfig.bar || ({})
    readonly property string savedWeatherLocation: String(root.settingsConfig.weatherLocation || "")
    readonly property bool weatherEnabled: root.settingsConfig.weatherEnabled || false

    readonly property var pages: [
        { id: "general", label: "General", icon: "dashboard" },
        { id: "themes", label: "Themes", icon: "palette" },
        { id: "bar", label: "Bar", icon: "bar" },
        { id: "launcher", label: "Launcher", icon: "search" },
        { id: "weather", label: "Weather", icon: "cloud" }
    ]
    readonly property var panelWidthOptions: [
        { value: 360, label: "Compact · 360 px" },
        { value: 420, label: "Default · 420 px" },
        { value: 520, label: "Wide · 520 px" },
        { value: 640, label: "Extra Wide · 640 px" }
    ]
    readonly property var textScaleOptions: [
        { value: 0.85, label: "Compact · 85%" },
        { value: 1.0, label: "Default · 100%" },
        { value: 1.1, label: "Comfortable · 110%" },
        { value: 1.2, label: "Large · 120%" },
        { value: 1.35, label: "Extra Large · 135%" },
        { value: 1.5, label: "Maximum · 150%" }
    ]
    readonly property var scrollStepOptions: [
        { value: 2, label: "2%" },
        { value: 5, label: "5%" },
        { value: 10, label: "10%" }
    ]
    readonly property var barPositionOptions: [
        { value: "off", label: "Off" },
        { value: "top", label: "Top" },
        { value: "bottom", label: "Bottom" }
    ]
    // The bar's sizes, each a list of the values offered and its default.
    readonly property var barSizes: [
        { key: "height", label: "Height", fallback: 40,
          options: [24, 28, 32, 36, 40, 44, 48, 56, 64].map(function(px) { return { value: px, label: px + " px" }; }) },
        { key: "width", label: "Width", fallback: 100,
          options: [25, 33, 50, 66, 75, 90, 100].map(function(percent) {
              return { value: percent, label: percent >= 100 ? "Full" : percent + "%" };
          }) },
        { key: "margin", label: "Margin", fallback: 0,
          options: [0, 2, 4, 8, 12, 16, 24, 32].map(function(px) { return { value: px, label: px === 0 ? "Docked" : px + " px" }; }) },
        { key: "gap", label: "Gap", fallback: 0,
          options: [0, 1, 2, 4, 6, 8, 12, 16].map(function(px) { return { value: px, label: px + " px" }; }) }
    ]
    readonly property var launcherRowOptions: [
        { value: 3, label: "3" },
        { value: 5, label: "5" },
        { value: 7, label: "7" },
        { value: 10, label: "10" }
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
        { value: 1, label: "1" },
        { value: 3, label: "3" },
        { value: 5, label: "5" },
        { value: 10, label: "10" },
        { value: -1, label: "All" }
    ]
    readonly property var powerModeOptions: [
        { value: "maximum", label: "Maximum" },
        { value: "balanced", label: "Balanced" },
        { value: "saver", label: "Saver" }
    ]
    readonly property var launchShuffleOptions: [
        { value: "off", label: "Off" },
        { value: "wallpaper", label: "Wallpaper" },
        { value: "theme", label: "Theme" },
        { value: "both", label: "Theme and wallpaper" }
    ]
    readonly property var weatherIssues: Services.FeatureSupport.issues.filter(function(issue) {
        return issue.id.indexOf("weather") === 0;
    })

    title: "Settings"
    iconName: "config"

    onActivePageChanged: pageEnter.restart()
    Component.onCompleted: {
        root.showRequestedPage();
    }

    function showRequestedPage() {
        var page = Services.DashboardService.settingsPage;
        if (page === "")
            return;
        Services.DashboardService.settingsPage = "";
        if (root.pages.some(function(entry) { return entry.id === page; }))
            root.activePage = page;
    }

    Connections {
        target: Services.DashboardService

        function onSettingsPageChanged() { root.showRequestedPage(); }
    }

    function speedLabel(value) {
        return value <= 0 ? "Off" : value + "×";
    }

    headerActions: Row {
        spacing: ThemeModule.Theme.spacingTiny
        opacity: savedTimer.running ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: ThemeModule.Theme.animDuration }
        }

        Components.AppIcon {
            name: "check"
            size: ThemeModule.Theme.iconSizeTiny
            iconColor: ThemeModule.Theme.success
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: "Saved"
            font.pixelSize: ThemeModule.Theme.fontSizeCaption
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.success
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    function configValue(source, key, fallback) {
        return source[key] !== undefined ? source[key] : fallback;
    }

    // Appends a note when config.ini holds a value the control does not offer.
    function explain(info, options, value, customLabel) {
        for (var i = 0; i < options.length; i++) {
            if (options[i].value === value)
                return info;
        }
        return info + " Set to " + customLabel + " in config.ini.";
    }

    function applyWeatherLocation() {
        if (root.weatherLocationEdit !== null)
            Services.ConfigService.setWeatherLocation(root.weatherLocationEdit.trim());
        locationInput.focus = false;
    }

    component Notice: Rectangle {
        id: notice

        property string heading: ""
        property string detail: ""
        property color toneColor: ThemeModule.Theme.warning

        width: parent ? parent.width : 0
        implicitHeight: noticeText.implicitHeight + ThemeModule.Theme.spacingSmall * 2
        radius: ThemeModule.Theme.borderRadiusSmall
        color: ThemeModule.Theme.alpha(notice.toneColor, ThemeModule.Theme.tintSubtle)
        border.width: ThemeModule.Theme.borderWidth
        border.color: ThemeModule.Theme.alpha(notice.toneColor, ThemeModule.Theme.tintOutline)

        Components.AppIcon {
            id: noticeIcon
            x: ThemeModule.Theme.spacingSmall
            y: ThemeModule.Theme.spacingSmall + Math.max(0, (noticeMetrics.height - height) / 2)
            name: "alert"
            size: ThemeModule.Theme.iconSizeSmall
            iconColor: notice.toneColor
        }

        FontMetrics {
            id: noticeMetrics
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
        }

        Column {
            id: noticeText
            anchors.left: noticeIcon.right
            anchors.leftMargin: ThemeModule.Theme.spacingSmall
            anchors.right: parent.right
            anchors.rightMargin: ThemeModule.Theme.spacingSmall
            y: ThemeModule.Theme.spacingSmall
            spacing: ThemeModule.Theme.spacingMicro

            Text {
                width: parent.width
                visible: notice.heading !== ""
                text: notice.heading
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                font.bold: true
                color: notice.toneColor
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                text: notice.detail
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: notice.heading !== "" ? ThemeModule.Theme.text : notice.toneColor
                wrapMode: Text.Wrap
            }
        }
    }

    Timer {
        id: savedTimer
        interval: 1600
    }

    Connections {
        target: Services.ConfigService

        function onSavingConfigChanged() {
            if (!Services.ConfigService.savingConfig && !Services.ConfigService.operationFailed)
                savedTimer.restart();
        }
    }

    FontMetrics {
        id: tabMetrics
        font.pixelSize: ThemeModule.Theme.fontSizeSmall
        font.family: ThemeModule.Theme.fontFamily
        font.bold: true
    }

    // Page tabs: the current one shows its name, the others share the remaining width.
    Item {
        id: tabStrip

        readonly property int gap: ThemeModule.Theme.spacingTiny
        readonly property int activeIndex: {
            for (var i = 0; i < root.pages.length; i++) {
                if (root.pages[i].id === root.activePage)
                    return i;
            }
            return 0;
        }
        // Reading the font keeps this current when the text scale changes.
        readonly property real activeWidth: Math.min(
            tabStrip.width - (ThemeModule.Theme.controlHeight + tabStrip.gap) * (root.pages.length - 1),
            ThemeModule.Theme.iconSizeSmall + ThemeModule.Theme.spacingTiny
                + Math.ceil(tabMetrics.advanceWidth(root.pages[tabStrip.activeIndex].label) + tabMetrics.font.pixelSize * 0)
                + ThemeModule.Theme.spacingMedium * 2)
        readonly property real restWidth: (tabStrip.width - tabStrip.activeWidth - tabStrip.gap * (root.pages.length - 1))
            / (root.pages.length - 1)

        width: parent.width
        height: Math.max(ThemeModule.Theme.controlHeight, tabMetrics.height + ThemeModule.Theme.spacingSmall * 2)

        Repeater {
            model: root.pages

            delegate: Rectangle {
                id: tab

                required property var modelData
                required property int index
                readonly property bool current: tab.index === tabStrip.activeIndex

                x: tab.index <= tabStrip.activeIndex
                    ? tab.index * (tabStrip.restWidth + tabStrip.gap)
                    : (tab.index - 1) * (tabStrip.restWidth + tabStrip.gap) + tabStrip.activeWidth + tabStrip.gap
                width: tab.current ? tabStrip.activeWidth : tabStrip.restWidth
                height: tabStrip.height
                radius: ThemeModule.Theme.borderRadiusSmall
                clip: true
                color: tab.current
                    ? ThemeModule.Theme.alpha(ThemeModule.Theme.accent, ThemeModule.Theme.tintStrong)
                    : (tabMouse.containsMouse ? ThemeModule.Theme.cardHover : ThemeModule.Theme.controlFill)
                border.width: ThemeModule.Theme.borderWidth
                border.color: tab.current ? ThemeModule.Theme.selectedBorder : "transparent"

                Behavior on x {
                    NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing }
                }
                Behavior on width {
                    NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing }
                }

                Accessible.role: Accessible.PageTab
                Accessible.name: tab.modelData.label
                Accessible.selected: tab.current
                Accessible.onPressAction: root.activePage = tab.modelData.id

                Row {
                    id: tabContent
                    anchors.centerIn: parent
                    spacing: tab.current ? ThemeModule.Theme.spacingTiny : 0

                    Components.AppIcon {
                        name: tab.modelData.icon
                        size: ThemeModule.Theme.iconSizeSmall
                        iconColor: tab.current
                            ? ThemeModule.Theme.accent
                            : (tabMouse.containsMouse ? ThemeModule.Theme.text : ThemeModule.Theme.subtext)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        width: Math.min(implicitWidth, tab.width - ThemeModule.Theme.iconSizeSmall
                            - ThemeModule.Theme.spacingTiny - ThemeModule.Theme.spacingSmall * 2)
                        elide: Text.ElideRight
                        visible: tab.current
                        opacity: tab.current ? 1 : 0
                        text: tab.modelData.label
                        font: tabMetrics.font
                        color: ThemeModule.Theme.text
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on opacity {
                            NumberAnimation { duration: ThemeModule.Theme.animDuration }
                        }
                    }
                }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activePage = tab.modelData.id
                }

                Components.Tooltip {
                    visible: !tab.current && tabMouse.containsMouse
                    text: tab.modelData.label
                }
            }
        }
    }

    Notice {
        visible: Services.ConfigService.operationFailed && Services.ConfigService.operationMessage !== ""
        detail: Services.ConfigService.operationMessage
        toneColor: ThemeModule.Theme.error
    }

    Item {
        width: parent.width
        height: ThemeModule.Theme.spacingTiny
    }

    Item {
        width: parent.width
        height: pageStack.height

        ParallelAnimation {
            id: pageEnter

            NumberAnimation {
                target: pageStack
                property: "opacity"
                from: 0
                to: 1
                duration: ThemeModule.Theme.animDuration
            }
            NumberAnimation {
                target: pageStack
                property: "x"
                from: ThemeModule.Theme.spacingSmall
                to: 0
                duration: ThemeModule.Theme.animDuration
                easing.type: ThemeModule.Theme.animEasing
            }
        }

        Column {
            id: pageStack
            width: parent.width

            Column {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall
                visible: root.activePage === "general"

                Components.SettingRow {
                    label: "Text size"
                    info: "Text size in the dashboard, launcher, and notifications."

                    Components.SelectMenu {
                        options: root.textScaleOptions
                        currentValue: root.configValue(root.settingsConfig, "textScale", 1.0)
                        fallbackLabel: Math.round(Number(currentValue) * 100) + "% · Custom"
                        onValueSelected: function(value) { Services.ConfigService.setTextScale(value); }
                    }
                }

                Components.SettingRow {
                    label: "Panel width"

                    Components.SelectMenu {
                        options: root.panelWidthOptions
                        currentValue: root.configValue(root.settingsConfig, "panelWidth", 420)
                        fallbackLabel: currentValue + " px · Custom"
                        onValueSelected: function(value) { Services.ConfigService.setPanelWidth(value); }
                    }
                }

                Components.SettingRow {
                    id: scrollStepRow
                    readonly property var step: root.configValue(root.settingsConfig, "audioScrollStep", 5)

                    label: "Volume scroll step"
                    info: root.explain("How much one scroll over the sidebar's volume icons changes the volume.",
                        root.scrollStepOptions, step, step + "%")

                    Components.SegmentedControl {
                        options: root.scrollStepOptions
                        currentValue: scrollStepRow.step
                        onValueSelected: function(value) { Services.ConfigService.setAudioScrollStep(value); }
                    }
                }

                Components.SettingRow {
                    id: toastsRow
                    readonly property var count: root.configValue(root.settingsConfig, "maxVisibleNotification", 3)

                    label: "Toasts on screen"
                    info: root.explain("Notifications shown at once. The oldest closes first.", root.notificationOptions,
                        count, String(count))

                    Components.SegmentedControl {
                        options: root.notificationOptions
                        currentValue: toastsRow.count
                        onValueSelected: function(value) { Services.ConfigService.setMaxVisibleNotification(value); }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall
                visible: root.activePage === "themes"

                Components.SettingRow {
                    label: "Draw wallpaper"
                    info: "Show the theme's wallpaper on the desktop. Turn off if another app sets your wallpaper."

                    Components.ToggleSwitch {
                        checked: Services.ThemeService.wallpaperEnabled
                        tooltipText: "Draw wallpaper"
                        onToggled: function(newState) { Services.ConfigService.setDrawWallpaper(newState); }
                    }
                }

                Components.SettingRow {
                    label: "Shuffle at launch"
                    info: "Pick a random wallpaper, theme, or both each time Speshell starts."

                    Components.SelectMenu {
                        options: root.launchShuffleOptions
                        currentValue: Services.ThemeService.launchShuffle || "off"
                        onValueSelected: function(value) { Services.ConfigService.setShuffleAtLaunch(value); }
                    }
                }

                Components.SettingRow {
                    label: "Power use"
                    info: "Maximum animates the theme's effects at your display's refresh rate, Balanced at 60 fps. "
                        + "Saver turns them off along with the interface's motion. Saving modes also look less often "
                        + "for recordings started outside Speshell. The sliders set how fast each surface's effects play."

                    Components.SelectMenu {
                        options: root.powerModeOptions
                        currentValue: Services.PowerService.mode
                        onValueSelected: function(value) { Services.ConfigService.setPowerMode(value); }
                    }
                }

                Row {
                    id: speedRow
                    readonly property real columnWidth: (width - spacing * 2) / 3

                    enabled: Services.EffectsService.enabled
                    opacity: enabled ? 1 : ThemeModule.Theme.disabledOpacity
                    width: parent.width
                    spacing: ThemeModule.Theme.spacingMedium

                    Repeater {
                        model: [
                            { surface: "launcher", label: "Launcher" },
                            { surface: "dashboard", label: "Dashboard" },
                            { surface: "wallpaper", label: "Wallpaper" }
                        ]

                        Components.StepSlider {
                            id: speedSlider
                            required property var modelData

                            width: speedRow.columnWidth
                            label: speedSlider.modelData.label
                            from: 0
                            to: 2
                            value: Services.EffectsService[speedSlider.modelData.surface + "Speed"]
                            format: root.speedLabel
                            onCommitted: function(value) { Services.ConfigService.setTransitionSpeed(speedSlider.modelData.surface, value); }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall
                visible: root.activePage === "bar"

                Components.SettingRow {
                    label: "Position"
                    info: "Experimental. A bar on every screen; its icons open the dashboard's panels. Margin is its distance from the screen's edge, and gap the space between it and the windows."

                    Components.SegmentedControl {
                        options: root.barPositionOptions
                        currentValue: root.configValue(root.barConfig, "position", "off")
                        onValueSelected: function(value) { Services.ConfigService.setBar("position", value); }
                    }
                }

                Grid {
                    id: barSizeGrid
                    readonly property real columnWidth: (width - columnSpacing) / 2

                    enabled: root.barConfig.position !== "off"
                    opacity: enabled ? 1 : ThemeModule.Theme.disabledOpacity
                    width: parent.width
                    columns: 2
                    columnSpacing: ThemeModule.Theme.spacingMedium
                    rowSpacing: ThemeModule.Theme.spacingSmall

                    Repeater {
                        model: root.barSizes

                        Column {
                            id: barSize
                            required property var modelData
                            readonly property var current: root.configValue(root.barConfig, barSize.modelData.key,
                                barSize.modelData.fallback)

                            width: barSizeGrid.columnWidth
                            spacing: ThemeModule.Theme.spacingTiny

                            Text {
                                text: barSize.modelData.label
                                font.pixelSize: ThemeModule.Theme.fontSizeCaption
                                font.family: ThemeModule.Theme.fontFamily
                                color: ThemeModule.Theme.subtext
                            }

                            Components.SelectMenu {
                                width: parent.width
                                options: barSize.modelData.options
                                currentValue: barSize.current
                                fallbackLabel: barSize.current + (barSize.modelData.key === "width" ? "%" : " px")
                                onValueSelected: function(value) { Services.ConfigService.setBar(barSize.modelData.key, value); }
                            }
                        }
                    }
                }

                Components.SettingRow {
                    enabled: root.barConfig.position !== "off"
                    label: "Full outline"
                    info: "Frame the bar along the screen's edges too, not only on the sides away from them."

                    Components.ToggleSwitch {
                        checked: root.barConfig.outline === "full"
                        tooltipText: "Full outline"
                        onToggled: function(newState) { Services.ConfigService.setBar("outline", newState ? "full" : "edges"); }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall
                visible: root.activePage === "launcher"

                Components.SettingRow {
                    id: resultsRow
                    readonly property var rows: root.configValue(root.launcherConfig, "visibleRows", 5)

                    label: "Visible results"
                    info: root.explain("Results shown before the list scrolls.", root.launcherRowOptions,
                        rows, rows + " rows")

                    Components.SegmentedControl {
                        options: root.launcherRowOptions
                        currentValue: resultsRow.rows
                        onValueSelected: function(value) { Services.ConfigService.setLauncherRows(value); }
                    }
                }

                Components.SettingRow {
                    label: "Width"

                    Components.SelectMenu {
                        options: root.launcherWidthOptions
                        currentValue: root.configValue(root.launcherConfig, "width", 540)
                        fallbackLabel: currentValue + " px · Custom"
                        onValueSelected: function(value) { Services.ConfigService.setLauncherWidth(value); }
                    }
                }

                Components.SettingRow {
                    label: "Web search"
                    info: "Used for ? searches. Other search engines can be set in config.ini."

                    Components.SelectMenu {
                        options: root.searchEngineOptions
                        currentValue: root.launcherConfig.searchUrl || "https://duckduckgo.com/?q={query}"
                        fallbackLabel: "Custom URL"
                        onValueSelected: function(value) { Services.ConfigService.setLauncherSearchUrl(value); }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall
                visible: root.activePage === "weather"

                Components.SettingRow {
                    label: "Show weather"
                    info: "Show the weather next to the clock."

                    Components.ToggleSwitch {
                        checked: root.weatherEnabled
                        tooltipText: "Show weather"
                        onToggled: function(newState) { Services.ConfigService.setWeatherEnabled(newState); }
                    }
                }

                Components.SettingRow {
                    enabled: root.weatherEnabled
                    label: "Location"
                    info: "A city name. Leave empty to detect it automatically."

                    Rectangle {
                        implicitWidth: 180
                        implicitHeight: Math.max(ThemeModule.Theme.controlHeightSmall, locationInput.implicitHeight + ThemeModule.Theme.spacingTiny * 2)
                            + ThemeModule.Theme.spacingMicro * 2
                        radius: ThemeModule.Theme.borderRadius
                        color: ThemeModule.Theme.controlFill
                        border.width: ThemeModule.Theme.borderWidth
                        border.color: locationInput.activeFocus ? ThemeModule.Theme.selectedBorder : ThemeModule.Theme.controlBorder

                        TextInput {
                            id: locationInput

                            readonly property bool dirty: root.weatherLocationEdit !== null
                                && root.weatherLocationEdit.trim() !== root.savedWeatherLocation

                            anchors.left: parent.left
                            anchors.leftMargin: ThemeModule.Theme.spacingSmall
                            anchors.right: applyLocation.visible ? applyLocation.left : parent.right
                            anchors.rightMargin: ThemeModule.Theme.spacingSmall
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.weatherLocationEdit !== null ? root.weatherLocationEdit : root.savedWeatherLocation
                            color: ThemeModule.Theme.text
                            selectionColor: ThemeModule.Theme.accent
                            selectedTextColor: ThemeModule.Theme.bg
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            clip: true
                            Accessible.name: "Weather location"
                            onTextEdited: root.weatherLocationEdit = text
                            onAccepted: root.applyWeatherLocation()
                            Keys.onEscapePressed: {
                                root.weatherLocationEdit = null;
                                locationInput.focus = false;
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: locationInput.text === ""
                                text: "Automatic"
                                font: locationInput.font
                                color: ThemeModule.Theme.overlay
                            }
                        }

                        Components.IconButton {
                            id: applyLocation
                            anchors.right: parent.right
                            anchors.rightMargin: ThemeModule.Theme.spacingMicro
                            anchors.verticalCenter: parent.verticalCenter
                            visible: locationInput.dirty
                            size: ThemeModule.Theme.controlHeightSmall - ThemeModule.Theme.spacingTiny
                            iconName: "check"
                            iconSize: ThemeModule.Theme.iconSizeSmall
                            iconColor: ThemeModule.Theme.accent
                            tooltipText: "Save location (Enter)"
                            onClicked: root.applyWeatherLocation()
                        }
                    }
                }

                Repeater {
                    model: root.weatherIssues

                    delegate: Notice {
                        required property var modelData

                        heading: modelData.title
                        detail: modelData.detail
                    }
                }
            }
        }
    }
}
