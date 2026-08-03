import QtQuick
import QtTest
import "../core/Config.js" as Config

TestCase {
    name: "Config"

    property string validConfig: [
        "[Appearance]",
        "colorScheme = nord",
        "panelWorkspace = special:dash",
        "panelWidth = 600",
        "panelMargin = 0",
        "",
        "[Audio]",
        "panelMode = separate",
        "scrollStep = 10",
        "",
        "[Audio.QuickSwitch]",
        "1 = Speakers",
        "2 = Display, HDMI",
        "",
        "[Audio.InputQuickSwitch]",
        "1 = Microphone",
        "",
        "[Audio.DeviceNames]",
        "alsa_output.test = Desk Speakers",
        "",
        "[Audio.InputDeviceNames]",
        "alsa_input.test = Desk Microphone",
        "",
        "[Launcher]",
        "width = 640",
        "visibleRows = 7",
        "searchUrl = https://example.com/search?q={query}",
        "",
        "[Launcher.Bangs]",
        "docs = https://example.com/docs?q={query}",
        "",
        "[Backlight]",
        "device = intel_backlight",
        "",
        "[Power]",
        "lockCommand = swaylock",
        "",
        "[Power.Arguments]",
        "1 = --daemonize",
        "2 = --color=00,00,00",
        "",
        "[Weather]",
        "enabled = true",
        "location = São Paulo",
        "",
        "[Notifications]",
        "maxVisible = -1"
    ].join("\n")

    function test_validFullConfig() {
        var result = Config.parseAndValidate(validConfig);
        verify(result.ok, result.errors.length > 0 ? result.errors[0].message : "");
        compare(result.config.colorScheme, "nord");
        compare(result.config.panelWorkspace, "special:dash");
        compare(result.config.panelWidth, 600);
        compare(result.config.panelMargin, 0);
        compare(result.config.audioPanelMode, "separate");
        compare(result.config.audioScrollStep, 10);
        compare(result.config.audioQuickSwitch, ["Speakers", "Display, HDMI"]);
        compare(result.config.audioDeviceNames["alsa_output.test"], "Desk Speakers");
        compare(result.config.audioInputQuickSwitch, ["Microphone"]);
        compare(result.config.audioInputDeviceNames["alsa_input.test"], "Desk Microphone");
        compare(result.config.launcher.width, 640);
        compare(result.config.launcher.visibleRows, 7);
        compare(result.config.launcher.bangs.docs, "https://example.com/docs?q={query}");
        compare(result.config.powerMenu.lockCommand, ["swaylock", "--daemonize", "--color=00,00,00"]);
        compare(result.config.weatherEnabled, true);
        compare(result.config.weatherLocation, "São Paulo");
        compare(result.config.maxVisibleNotification, -1);
    }

    function test_defaults() {
        var result = Config.parseAndValidate("[Appearance]\n");
        verify(result.ok);
        compare(result.config.panelMargin, 16);
        compare(result.config.audioPanelMode, "combined");
        compare(result.config.launcher.visibleRows, 5);
        compare(result.config.powerMenu.lockCommand, ["hyprlock"]);
    }

    function test_invalid_data() {
        return [
            { tag: "bad margin", text: "[Appearance]\npanelMargin = -1", message: "Expected a value from 0 to 128" },
            { tag: "partial integer", text: "[Launcher]\nvisibleRows = 5rows", message: "Expected a whole number" },
            { tag: "bad boolean", text: "[Weather]\nenabled = yes", message: "Expected true or false" },
            { tag: "bad mode", text: "[Audio]\npanelMode = merged", message: "Expected one of" },
            { tag: "insecure URL", text: "[Launcher]\nsearchUrl = http://example.com/?q={query}", message: "must use HTTPS" },
            { tag: "missing placeholder", text: "[Launcher]\nsearchUrl = https://example.com/", message: "exactly one {query}" },
            { tag: "reserved bang", text: "[Launcher.Bangs]\naudio = https://example.com/?q={query}", message: "is reserved" },
            { tag: "malformed line", text: "[Appearance]\npanelWidth 400", message: "Expected 'key = value'" }
        ];
    }

    function test_invalid(data) {
        var result = Config.parseAndValidate(data.text);
        verify(!result.ok);
        var messages = result.errors.map(function(error) { return error.message; }).join("\n");
        verify(messages.indexOf(data.message) >= 0, messages);
    }

    function test_setIniProperty() {
        var source = "[Appearance]\npanelMargin = 16\n\n[Weather]\nenabled = false\n";
        var replaced = Config.setIniProperty(source, "Appearance", "panelMargin", 0);
        verify(replaced.indexOf("panelMargin = 0") >= 0);
        verify(Config.parseAndValidate(replaced).ok);

        var inserted = Config.setIniProperty(replaced, "Weather", "location", "São Paulo");
        verify(inserted.indexOf("location = São Paulo") >= 0);
        verify(Config.parseAndValidate(inserted).ok);

        var appended = Config.setIniProperty(inserted, "Notifications", "maxVisible", 5);
        verify(appended.indexOf("[Notifications]\nmaxVisible = 5") >= 0);
        verify(Config.parseAndValidate(appended).ok);
    }
}
