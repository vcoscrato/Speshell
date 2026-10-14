import QtQuick
import "WidgetRegistry.js" as WidgetRegistry

// Loads one registered widget by name, as the dashboard shows it: expanded, told when
// its surface shows, and given its part of the config. The dashboard and the bar's
// dropdowns both host widgets through it, so a panel looks and works the same in each.
Loader {
    id: root

    property string name: ""
    property var config: null
    property bool presented: false
    // The audio panel shows the speaker alone, its microphone left to its own panel. The
    // dashboard follows [Audio] panelMode; the bar always gives each its own button.
    property bool audioSeparate: !!root.config && root.config.audioPanelMode === "separate"
    // Untyped, for the properties only some widgets have.
    readonly property var widget: root.item

    function configure() {
        var cfg = root.config || ({});
        var widget = root.widget;
        if (!widget)
            return;
        if (root.name === "audioControl") {
            if ("quickSwitchDevices" in widget)
                widget.quickSwitchDevices = cfg.audioQuickSwitch || [];
            if ("deviceDisplayNames" in widget)
                widget.deviceDisplayNames = cfg.audioDeviceNames || ({});
            if ("inputQuickSwitchDevices" in widget)
                widget.inputQuickSwitchDevices = cfg.audioInputQuickSwitch || [];
            if ("inputDeviceDisplayNames" in widget)
                widget.inputDeviceDisplayNames = cfg.audioInputDeviceNames || ({});
        } else if (root.name === "audioInputControl") {
            if ("quickSwitchDevices" in widget)
                widget.quickSwitchDevices = cfg.audioInputQuickSwitch || [];
            if ("deviceDisplayNames" in widget)
                widget.deviceDisplayNames = cfg.audioInputDeviceNames || ({});
        }
    }

    active: root.name !== ""
    source: root.active ? WidgetRegistry.source(root.name) : ""

    onConfigChanged: root.configure()
    onLoaded: {
        var widget = root.widget;
        if ("presented" in widget)
            widget.presented = Qt.binding(function() { return root.presented; });
        if (root.name === "audioControl")
            widget.mode = Qt.binding(function() { return root.audioSeparate ? "output" : "combined"; });
        if ("collapsible" in widget) {
            widget.collapsible = false;
            widget.collapsed = false;
        }
        root.configure();
    }
}
