//@ pragma UseQApplication
//@ pragma AppId speshell
pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import "services" as Services
import "theme" as ThemeModule
import "core" as Core

ShellRoot {
    id: root

    function applyConfig(configValue) {
        if (!configValue)
            return;
        ThemeModule.Theme.textScale = configValue.textScale;
        Services.ThemeService.wallpaperEnabled = configValue.drawWallpaper;
        Services.EffectsService.launcherSpeed = configValue.launcherTransitionSpeed;
        Services.EffectsService.dashboardSpeed = configValue.dashboardTransitionSpeed;
        Services.EffectsService.wallpaperSpeed = configValue.wallpaperTransitionSpeed;
        Services.ThemeService.launchShuffle = configValue.shuffleAtLaunch;
        Services.AudioService.scrollStep = configValue.audioScrollStep;
        Services.AudioService.outputQuickSwitch = configValue.audioQuickSwitch;
        Services.AudioService.outputDeviceNames = configValue.audioDeviceNames;
        Services.AudioService.inputQuickSwitch = configValue.audioInputQuickSwitch;
        Services.AudioService.inputDeviceNames = configValue.audioInputDeviceNames;
        Services.WeatherService.location = configValue.weatherLocation;
        Services.WeatherService.enabled = configValue.weatherEnabled;
        Services.FeatureSupport.configuredBacklightDevice = configValue.backlightDevice;
        Services.PowerService.lockCommand = configValue.powerMenu.lockCommand;
        Services.PowerService.mode = configValue.powerMode;
        Services.NotificationService.maxVisible = configValue.maxVisibleNotification;
        Services.ToolsService.ocrLanguages = configValue.tools.ocrLanguages;
        Services.ToolsService.dictationLanguages = configValue.tools.dictationLanguages;
        Services.ToolsService.dictationVocabulary = configValue.tools.dictationVocabulary;
        Services.ToolsService.dictationModel = configValue.tools.dictationModel;
        Services.DashboardService.workspaceName = configValue.panelWorkspace;
        Services.DashboardService.panelWidth = configValue.panelWidth;
        Services.DashboardService.panelMargin = configValue.panelMargin;
    }

    Connections {
        target: Services.ConfigService

        function onConfigChanged() {
            if (Services.ConfigService.config)
                root.applyConfig(Services.ConfigService.config);
        }
    }

    Binding {
        target: ThemeModule.Theme
        property: "paletteOverride"
        value: Services.ThemeService.colors
    }

    // Saver keeps the interface still.
    Binding {
        target: ThemeModule.Theme
        property: "motion"
        value: Services.PowerService.mode !== "saver"
    }

    Binding {
        target: Services.EffectsService
        property: "dir"
        value: Services.ThemeService.activeEffectsDir
    }

    LazyLoader {
        active: Services.ConfigService.valid

        component: Core.Runtime {
            config: Services.ConfigService.config
        }
    }

    Core.ConfigErrorWindow {
        active: Services.ConfigService.invalid
    }

    Component.onCompleted: Services.ConfigService.load()
}
