import QtQuick
import QtTest
import "../core/WidgetRegistry.js" as WidgetRegistry
import "../services/AppProvider.js" as AppProvider
import "../services/BangProvider.js" as BangProvider

TestCase {
    name: "LauncherProviders"

    property var entries: [
        {
            id: "org.example.Editor.desktop",
            name: "Text Editor",
            genericName: "Code Editor",
            comment: "Edit source files",
            categories: ["Development"],
            keywords: ["code", "text"],
            noDisplay: false,
            icon: "editor"
        },
        {
            id: "org.example.Browser.desktop",
            name: "Web Browser",
            genericName: "Browser",
            comment: "Browse the web",
            categories: ["Network"],
            keywords: ["internet"],
            noDisplay: false,
            icon: "browser"
        },
        {
            id: "com.visualstudio.code.desktop",
            name: "Visual Studio Code",
            genericName: "",
            comment: "",
            categories: [],
            keywords: [],
            noDisplay: false,
            icon: "code"
        },
        { id: "hidden.desktop", name: "Hidden", noDisplay: true }
    ]

    function test_buildAndSearchIndex() {
        var index = AppProvider.buildIndex(entries);
        compare(index.length, 3);
        compare(AppProvider.search(index, "text edit", {}, 10)[0].title, "Text Editor");
        compare(AppProvider.search(index, "internet", {}, 10)[0].title, "Web Browser");
    }

    function test_initialsAndFuzzyMatching() {
        var index = AppProvider.buildIndex(entries);
        compare(AppProvider.initials("GitHub Desktop"), "ghd");
        compare(AppProvider.search(index, "vsc", {}, 10)[0].title, "Visual Studio Code");
        compare(AppProvider.search(index, "brwsr", {}, 10)[0].title, "Web Browser");
        compare(AppProvider.search(index, "zzz", {}, 10).length, 0);

        var exact = AppProvider.search(index, "code", {}, 10);
        compare(exact[0].title, "Visual Studio Code");
    }

    function test_usageRanksEmptyQuery() {
        var index = AppProvider.buildIndex(entries);
        var usage = { "org.example.Browser.desktop": { count: 5 } };
        compare(AppProvider.search(index, "", usage, 10)[0].title, "Web Browser");
    }

    function test_bangEncodingAndAvailability() {
        var config = {
            searchUrl: "https://example.com/?q={query}",
            bangs: { docs: "https://docs.example.com/?q={query}" }
        };
        var docs = BangProvider.bangResults("!docs qml singleton", config, WidgetRegistry.navigationPanels);
        compare(docs.length, 1);
        compare(docs[0].payload.url, "https://docs.example.com/?q=qml%20singleton");

        var unavailable = WidgetRegistry.navigationPanels.filter(function(name) { return name !== "displayControl"; });
        compare(BangProvider.bangResults("!display", config, unavailable).length, 0);
    }

    function test_bangCompletion() {
        var config = { searchUrl: "https://example.com/?q={query}", bangs: { gh: "https://github.com/search?q={query}" } };
        var suggestions = BangProvider.bangResults("!g", config, WidgetRegistry.navigationPanels);
        var gh = suggestions.filter(function(result) { return result.id === "bang:gh"; })[0];
        compare(gh.completion, "!gh ");
        verify(gh.completeOnActivate);

        var network = BangProvider.bangResults("!netw", config, WidgetRegistry.navigationPanels)[0];
        compare(network.completion, "!network");
        verify(!network.completeOnActivate);
    }

    function test_searchAndUnknownBangFallback() {
        var config = { searchUrl: "https://example.com/?q={query}", bangs: {} };
        compare(
            BangProvider.searchResult("? qml singleton", config)[0].payload.url,
            "https://example.com/?q=qml%20singleton"
        );
        compare(
            BangProvider.bangResults("!unknown cats", config, WidgetRegistry.navigationPanels)[0].payload.url,
            "https://example.com/?q=!unknown%20cats"
        );
    }

    function test_widgetRegistryAliases() {
        compare(WidgetRegistry.canonicalName("configPanel"), "settings");
        verify(WidgetRegistry.isReservedBottomPanel("settings"));
        compare(WidgetRegistry.panelForBang("home"), "main");
        compare(WidgetRegistry.panelForBang("settings"), "settings");
        compare(WidgetRegistry.panelForBang("config"), "settings");
    }

    function test_settingsBangs() {
        var config = { searchUrl: "https://example.com/?q={query}", bangs: {} };
        var exact = BangProvider.bangResults("!settings", config, WidgetRegistry.navigationPanels);
        compare(exact[0].payload.panel, "settings");
        var alias = BangProvider.bangResults("!config", config, WidgetRegistry.navigationPanels);
        compare(alias[0].payload.panel, "settings");
        var prefix = BangProvider.bangResults("!conf", config, WidgetRegistry.navigationPanels);
        compare(prefix[0].payload.panel, "settings");
    }

    function test_plainSearchFindsPanels() {
        var panels = AppProvider.buildExtraIndex(BangProvider.panelSearchItems(WidgetRegistry.navigationPanels));
        var index = AppProvider.buildIndex(entries).concat(panels);
        var results = AppProvider.search(index, "settings", {}, 10);
        compare(results[0].kind, "panel");
        compare(results[0].payload.panel, "settings");
        compare(AppProvider.search(index, "config", {}, 10)[0].payload.panel, "settings");
        compare(AppProvider.search(index, "", {}, 10).filter(function(result) { return result.kind === "panel"; }).length, 0);

        var withoutBluetooth = WidgetRegistry.navigationPanels.filter(function(name) { return name !== "bluetoothPanel"; });
        var limited = AppProvider.buildExtraIndex(BangProvider.panelSearchItems(withoutBluetooth));
        compare(AppProvider.search(limited, "bluetooth", {}, 10).length, 0);
    }
}
