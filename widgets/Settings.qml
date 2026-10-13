pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
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
    readonly property string savedWeatherLocation: String(root.settingsConfig.weatherLocation || "")
    readonly property bool weatherEnabled: root.settingsConfig.weatherEnabled || false

    readonly property var pages: [
        { id: "general", label: "General", icon: "dashboard" },
        { id: "themes", label: "Themes", icon: "palette" },
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
    readonly property var frameRateOptions: [30, 60, 75, 90, 120, 144, 165, 240, 300].map(function(rate) {
        return { value: rate, label: rate + " fps" };
    })
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

                Controls.ToolTip.visible: !tab.current && tabMouse.containsMouse
                Controls.ToolTip.text: tab.modelData.label
                Controls.ToolTip.delay: 300
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
                    label: "Effects"
                    info: "How smooth the theme's animations are. The sliders below set how fast each one plays, or turn it off."

                    Components.SelectMenu {
                        enabled: Services.EffectsService.transitionsEnabled
                        options: root.frameRateOptions
                        currentValue: Services.EffectsService.frameRate
                        fallbackLabel: Services.EffectsService.frameRate + " fps"
                        onValueSelected: function(value) { Services.ConfigService.setTransitionFrameRate(value); }
                    }
                }

                Row {
                    id: speedRow
                    readonly property real columnWidth: (width - spacing * 2) / 3

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
