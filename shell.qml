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
        ThemeModule.Theme.paletteName = configValue.colorScheme;
        Services.WeatherService.location = configValue.weatherLocation;
        Services.WeatherService.enabled = configValue.weatherEnabled;
        Services.FeatureSupport.configuredBacklightDevice = configValue.backlightDevice;
        Services.PowerService.lockCommand = configValue.powerMenu.lockCommand;
    }

    Connections {
        target: Services.ConfigService

        function onConfigChanged() {
            if (Services.ConfigService.config)
                root.applyConfig(Services.ConfigService.config);
        }
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
