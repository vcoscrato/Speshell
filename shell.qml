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
        Services.AudioService.scrollStep = configValue.audioScrollStep;
        Services.WeatherService.location = configValue.weatherLocation;
        Services.WeatherService.enabled = configValue.weatherEnabled;
        Services.FeatureSupport.configuredBacklightDevice = configValue.backlightDevice;
        Services.PowerService.lockCommand = configValue.powerMenu.lockCommand;
        Services.NotificationService.maxVisible = configValue.maxVisibleNotification;
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
        property: "paletteName"
        value: Services.ThemeService.scheme
    }

    Binding {
        target: ThemeModule.Theme
        property: "paletteOverride"
        value: Services.ThemeService.colors
    }

    Binding {
        target: ThemeModule.Theme
        property: "accentOverride"
        value: Services.ThemeService.accent
    }

    Binding {
        target: Services.EffectsService
        property: "name"
        value: Services.ThemeService.effects
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
