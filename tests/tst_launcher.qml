import QtQuick
import QtTest
import "../core/WidgetRegistry.js" as WidgetRegistry
import "../services/AppProvider.js" as AppProvider
import "../services/BangProvider.js" as BangProvider

TestCase {
    name: "Launcher"

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
    readonly property var config: ({
        searchUrl: "https://example.com/?q={query}",
        bangs: { docs: "https://docs.example.com/?q={query}" }
    })

    function topResult(query, usage) {
        var results = AppProvider.search(AppProvider.buildIndex(entries), query, usage || {}, 10);
        return results.length > 0 ? results[0].title : "";
    }

    function test_hiddenEntriesAreLeftOut() {
        compare(AppProvider.buildIndex(entries).length, 3);
        compare(topResult("hidden"), "");
    }

    function test_matchesNamesAndKeywords() {
        compare(topResult("text edit"), "Text Editor");
        compare(topResult("internet"), "Web Browser");
    }

    function test_matchesInitialsAndSkippedLetters() {
        compare(topResult("vsc"), "Visual Studio Code");
        compare(topResult("brwsr"), "Web Browser");
        compare(topResult("zzz"), "");
    }

    function test_nameOutranksKeyword() {
        compare(topResult("code"), "Visual Studio Code");
    }

    function test_emptyQueryRanksByUsage() {
        compare(topResult("", { "org.example.Browser.desktop": { count: 5 } }), "Web Browser");
    }

    function test_bangEncodesItsQuery() {
        var results = BangProvider.bangResults("!docs qml singleton", config, WidgetRegistry.navigationPanels);
        compare(results.length, 1);
        compare(results[0].payload.url, "https://docs.example.com/?q=qml%20singleton");
    }

    function test_unavailablePanelHasNoBang() {
        var panels = WidgetRegistry.navigationPanels.filter(function(name) { return name !== "displayControl"; });
        compare(BangProvider.bangResults("!display", config, panels).length, 0);
    }

    function test_unknownBangSearchesTheWeb() {
        compare(BangProvider.searchResult("? qml singleton", config)[0].payload.url,
            "https://example.com/?q=qml%20singleton");
        compare(BangProvider.bangResults("!unknown cats", config, WidgetRegistry.navigationPanels)[0].payload.url,
            "https://example.com/?q=!unknown%20cats");
    }
}
