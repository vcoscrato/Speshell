pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "AppProvider.js" as AppProvider
import "CalculatorProvider.js" as CalculatorProvider
import "BangProvider.js" as BangProvider

Singleton {
    id: root

    property string query: ""
    property var results: []
    property var appIndex: []
    property var usage: ({})
    property bool saveQueued: false
    property bool usageLoaded: false
    property bool savingUsage: false
    property string writeUsageText: ""
    property string saveError: ""
    property var pendingLaunches: ({})
    property string activationError: ""
    readonly property string usagePath: ConfigService.dataDir !== ""
        ? ConfigService.dataDir + "/launcher-usage.json"
        : ""
    readonly property var launcherConfig: ConfigService.config && ConfigService.config.launcher
        ? ConfigService.config.launcher
        : ({
            searchUrl: "https://duckduckgo.com/?q={query}",
            bangs: ({})
        })

    function setQuery(value) {
        var next = String(value || "");
        if (root.query === next)
            return;
        root.query = next;
        root.activationError = "";
        root.rebuild();
    }

    function clearQuery() {
        root.setQuery("");
    }

    function rebuildAppIndex() {
        var entries = DesktopEntries.applications && DesktopEntries.applications.values
            ? DesktopEntries.applications.values
            : [];
        root.appIndex = AppProvider.buildIndex(entries);
        root.rebuild();
    }

    function calculatorResults(calculation) {
        if (!calculation.candidate)
            return [];
        if (!calculation.ok) {
            return [{
                id: "calculator:error",
                kind: "error",
                title: "Invalid expression",
                subtitle: calculation.error,
                iconName: "alert",
                iconSource: "",
                badge: "CALC",
                activatable: false,
                payload: ({})
            }];
        }
        return [{
            id: "calculator:" + calculation.expression,
            kind: "calculator",
            title: calculation.result,
            subtitle: calculation.expression + "  ·  Enter to copy",
            iconName: "calculator",
            iconSource: "",
            badge: "CALC",
            activatable: true,
            payload: { text: calculation.result }
        }];
    }

    function rebuild() {
        var trimmed = root.query.trim();
        if (trimmed.indexOf("!") === 0) {
            root.results = BangProvider.bangResults(
                trimmed,
                root.launcherConfig,
                DashboardService.availablePanelNames
            );
            return;
        }
        if (trimmed.indexOf("?") === 0) {
            root.results = BangProvider.searchResult(trimmed, root.launcherConfig);
            return;
        }

        var calculation = CalculatorProvider.evaluate(trimmed);
        if (calculation.candidate) {
            root.results = root.calculatorResults(calculation);
            return;
        }
        root.results = AppProvider.search(root.appIndex, trimmed, root.usage, 100);
    }

    function recordLaunch(appId) {
        if (!appId)
            return;
        if (!root.usageLoaded) {
            var pending = root.pendingLaunches;
            pending[appId] = (pending[appId] || 0) + 1;
            root.pendingLaunches = pending;
        }

        var next = ({});
        var keys = Object.keys(root.usage || ({}));
        for (var i = 0; i < keys.length; i++)
            next[keys[i]] = root.usage[keys[i]];
        var current = next[appId];
        var count = typeof current === "number"
            ? current
            : (current && typeof current === "object" ? Number(current.count) || 0 : 0);
        next[appId] = { count: count + 1, lastUsed: new Date().toISOString() };
        root.usage = next;
        root.saveUsage();
    }

    function activate(result) {
        root.activationError = "";
        if (!result || result.activatable === false)
            return false;
        var payload = result.payload || ({});
        if (result.kind === "app" && payload.entry) {
            root.recordLaunch(payload.appId);
            payload.entry.execute();
            return true;
        }
        if (result.kind === "calculator") {
            ClipboardService.copyText(payload.text || "");
            return true;
        }
        if (result.kind === "panel") {
            var opened = DashboardService.openPanel(payload.panel || "");
            if (!opened)
                root.activationError = DashboardService.errorMessage;
            return opened;
        }
        if (result.kind === "web" && payload.url) {
            Qt.openUrlExternally(payload.url);
            return true;
        }
        root.activationError = "This launcher result cannot be activated.";
        return false;
    }

    function emptyMessage() {
        var trimmed = root.query.trim();
        if (trimmed.indexOf("?") === 0)
            return "Type a web search after ?";
        if (trimmed.indexOf("!") === 0)
            return "No matching available panels or configured bangs";
        return "No applications found";
    }

    function readUsage() {
        if (root.usagePath === "" || root.usageLoaded)
            return;
        usageFile.reload();
    }

    function saveUsage() {
        if (root.usagePath === "")
            return;
        if (!root.usageLoaded || root.savingUsage) {
            root.saveQueued = true;
            return;
        }
        root.writeUsageText = JSON.stringify(root.usage || ({}));
        root.savingUsage = true;
        root.saveError = "";
        usageFile.setText(root.writeUsageText);
    }

    function finishUsageLoad(text) {
        if (root.usageLoaded)
            return;
        var parsed = ({});
        try {
            parsed = JSON.parse(text || "{}");
        } catch (usageError) {
            parsed = ({});
        }
        var loadedUsage = parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : ({});
        var pendingIds = Object.keys(root.pendingLaunches);
        for (var i = 0; i < pendingIds.length; i++) {
            var id = pendingIds[i];
            var current = loadedUsage[id];
            var count = typeof current === "number" ? current
                : (current && typeof current === "object" ? Number(current.count) || 0 : 0);
            loadedUsage[id] = { count: count + root.pendingLaunches[id], lastUsed: new Date().toISOString() };
        }
        root.pendingLaunches = ({});
        root.usage = loadedUsage;
        root.usageLoaded = true;
        if (root.saveQueued) {
            root.saveQueued = false;
            root.saveUsage();
        }
    }

    FileView {
        id: usageFile
        path: root.usagePath
        atomicWrites: true
        printErrors: false
        onLoaded: root.finishUsageLoad(usageFile.text())
        onLoadFailed: root.finishUsageLoad("{}")
        onSaved: {
            root.savingUsage = false;
            root.writeUsageText = "";
            if (root.saveQueued) {
                root.saveQueued = false;
                root.saveUsage();
            }
        }
        onSaveFailed: {
            root.savingUsage = false;
            root.writeUsageText = "";
            root.saveError = "Could not save launcher usage.";
        }
    }

    Component.onCompleted: {
        root.readUsage();
        root.rebuildAppIndex();
    }

    onUsagePathChanged: {
        root.usageLoaded = false;
        root.readUsage();
    }
    onUsageChanged: root.rebuild()

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.rebuildAppIndex(); }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.rebuildAppIndex(); }
    }

    Connections {
        target: ConfigService
        function onConfigChanged() { root.rebuild(); }
    }

    Connections {
        target: DashboardService
        function onAvailablePanelNamesChanged() { root.rebuild(); }
    }
}
