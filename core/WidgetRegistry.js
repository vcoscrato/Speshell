.pragma library

var entries = ({
    about:              { source: "../widgets/About.qml",              icon: "info", capability: "",                 bang: "about",         label: "About" },
    audioControl:       { source: "../widgets/AudioControl.qml",       icon: "audio-output", capability: "",          bang: "audio",         label: "Audio output" },
    audioInputControl:  { source: "../widgets/AudioInputControl.qml",  icon: "audio-input", capability: "",           bang: "mic",           label: "Microphone" },
    batteryStatus:      { source: "../widgets/BatteryStatus.qml",      icon: "battery", capability: "battery",        bang: "battery",       label: "Battery" },
    bluetoothPanel:     { source: "../widgets/BluetoothPanel.qml",     icon: "bluetooth", capability: "bluetooth",    bang: "bluetooth",     label: "Bluetooth" },
    calendar:           { source: "../widgets/Calendar.qml",           icon: "calendar", capability: "",              bang: "calendar",      label: "Calendar" },
    clipboardManager:   { source: "../widgets/ClipboardManager.qml",   icon: "clipboard", capability: "",             bang: "clipboard",     label: "Clipboard" },
    clock:              { source: "../widgets/Clock.qml",              icon: "timer", capability: "",                 bang: "clock",         label: "Clock and timer" },
    displayControl:     { source: "../widgets/DisplayControl.qml",     icon: "display", capability: "display",         bang: "display",       label: "Displays" },
    main:               { source: "../widgets/Main.qml",               icon: "dashboard", capability: "",             bang: "home",          label: "Home" },
    networkPanel:       { source: "../widgets/NetworkPanel.qml",       icon: "wifi", capability: "",                  bang: "network",       label: "Network" },
    notes:              { source: "../widgets/Notes.qml",              icon: "notes", capability: "",                 bang: "notes",         label: "Notes" },
    notificationCenter: { source: "../widgets/NotificationCenter.qml", icon: "bell", capability: "",                  bang: "notifications", label: "Notifications" },
    nowPlaying:         { source: "../widgets/NowPlaying.qml",         icon: "media", capability: "",                 bang: "media",         label: "Now playing" },
    powerMenu:          { source: "../widgets/PowerMenu.qml",          icon: "power", capability: "",                 bang: "power",         label: "Power menu" },
    settings:           { source: "../widgets/Settings.qml",           icon: "config", capability: "",                bang: "config",        label: "Settings" }
});

var aliases = ({ configPanel: "settings" });
var primaryPanel = "main";
var primaryPanelWidgets = ["nowPlaying", "notificationCenter"];
var headerPanel = "clock";
var sidebarPanels = [
    "audioControl", "audioInputControl", "displayControl", "batteryStatus",
    "notes", "clipboardManager", "networkPanel", "bluetoothPanel"
];
var reservedBottomPanels = ["calendar", "settings", "about", "powerMenu"];
var defaultReservedBottomPanel = "calendar";
var navigationPanels = [primaryPanel, headerPanel]
    .concat(primaryPanelWidgets)
    .concat(sidebarPanels)
    .concat(reservedBottomPanels);

function canonicalName(name) {
    var key = String(name || "");
    return Object.prototype.hasOwnProperty.call(aliases, key) ? aliases[key] : key;
}

function has(name) {
    return Object.prototype.hasOwnProperty.call(entries, canonicalName(name));
}

function entry(name) {
    var key = canonicalName(name);
    return has(key) ? entries[key] : null;
}

function source(name) {
    var value = entry(name);
    return value ? value.source : "";
}

function icon(name) {
    var value = entry(name);
    return value ? value.icon : "missing";
}

function label(name) {
    var value = entry(name);
    return value ? value.label : "";
}

function names() {
    return Object.keys(entries);
}

function isReservedBottomPanel(name) {
    return reservedBottomPanels.indexOf(canonicalName(name)) >= 0;
}

function isPrimaryPanel(name) {
    return canonicalName(name) === primaryPanel;
}

function isPrimaryPanelWidget(name) {
    return primaryPanelWidgets.indexOf(canonicalName(name)) >= 0;
}

function isHeaderPanel(name) {
    return canonicalName(name) === headerPanel;
}

function isSidebarPanel(name) {
    return sidebarPanels.indexOf(canonicalName(name)) >= 0;
}

function panelForBang(bang) {
    var requested = String(bang || "");
    var widgetNames = names();
    for (var i = 0; i < widgetNames.length; i++) {
        if (entries[widgetNames[i]].bang === requested)
            return widgetNames[i];
    }
    return "";
}

function bangPanels() {
    var result = [];
    var widgetNames = names();
    for (var i = 0; i < widgetNames.length; i++) {
        var widget = widgetNames[i];
        result.push({
            bang: entries[widget].bang,
            panel: widget,
            title: entries[widget].label,
            icon: entries[widget].icon
        });
    }
    result.sort(function(a, b) { return a.bang.localeCompare(b.bang); });
    return result;
}
