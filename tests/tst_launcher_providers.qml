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
        { id: "hidden.desktop", name: "Hidden", noDisplay: true }
    ]

    function test_buildAndSearchIndex() {
        var index = AppProvider.buildIndex(entries);
        compare(index.length, 2);
        compare(AppProvider.search(index, "text edit", {}, 10)[0].title, "Text Editor");
        compare(AppProvider.search(index, "internet", {}, 10)[0].title, "Web Browser");
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
    }
}
