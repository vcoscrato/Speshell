import QtQuick
import QtTest
import "../services/ThemeProvider.js" as ThemeProvider

TestCase {
    name: "ThemeProvider"

    readonly property string themesDir: "/home/me/.config/speshell/themes"
    readonly property string scan: [
        "theme\tfire-nation",
        "ini\t[Theme]",
        "ini\tname = Fire Nation",
        "ini\tscheme = gruvbox",
        "ini\teffects = fire",
        "ini\t[Colors]",
        "ini\taccent = #e5482e",
        "ini\tbase = #1d1416",
        "theme\tbroken",
        "ini\t[Theme]",
        "ini\tscheme = neon",
        "ini\t[Colors]",
        "ini\ttext = white",
        "ini\tglow = #ffffff",
        "wall\t/home/me/.config/speshell/themes/fire-nation/agni-kai.jpg",
        "wall\t/home/me/.config/speshell/themes/fire-nation/zuko/ember_island.png",
        "wall\t/home/me/.config/speshell/themes/nord/fjord.webp",
        "wall\t/home/me/.config/speshell/themes/loose.jpg",
        ""
    ].join("\n")

    function test_parseScan() {
        var parsed = ThemeProvider.parseScan(scan, themesDir);
        compare(parsed.themes.map(function(t) { return t.id; }), ["broken", "fire-nation", "nord"]);
        var fire = ThemeProvider.findTheme(parsed.themes, "fire-nation");
        compare(fire.name, "Fire Nation");
        compare(fire.effects, "fire");
        compare(fire.colors.accent, "#e5482e");
        compare(fire.colors.base, "#1d1416");
        compare(fire.errors.length, 0);
        compare(parsed.wallpapers.map(function(w) { return w.theme; }), ["fire-nation", "fire-nation", "nord"]);
        compare(parsed.wallpapers[1].title, "ember island");
    }

    function test_parseTheme_errors() {
        var broken = ThemeProvider.findTheme(ThemeProvider.parseScan(scan, themesDir).themes, "broken");
        compare(broken.scheme, ThemeProvider.defaultTheme);
        compare(broken.colors, ({}));
        compare(broken.errors.length, 3);
        verify(broken.errors[0].indexOf("unknown scheme") >= 0);
        compare(ThemeProvider.parseTheme("x", "[Theme]\neffects = ../fire").effects, "");
    }

    function test_folderWithoutIni() {
        var nord = ThemeProvider.findTheme(ThemeProvider.parseScan(scan, themesDir).themes, "nord");
        compare(nord.name, "nord");
        compare(nord.scheme, "gruvbox");
        compare(nord.builtin, false);
    }

    function test_allThemes() {
        var all = ThemeProvider.allThemes(ThemeProvider.parseScan(scan, themesDir).themes);
        // The "nord" folder replaces the built-in Nord scheme.
        compare(all.filter(function(t) { return t.id === "nord"; }).length, 1);
        compare(ThemeProvider.findTheme(all, "nord").builtin, false);
        compare(ThemeProvider.findTheme(all, "dracula").builtin, true);
        compare(all.length, 3 + ThemeProvider.schemes.length - 1);
    }

    function test_themeFor() {
        compare(ThemeProvider.themeFor(themesDir + "/fire-nation/zuko/a.png", themesDir), "fire-nation");
        compare(ThemeProvider.themeFor(themesDir + "/loose.jpg", themesDir), "");
        compare(ThemeProvider.themeFor("/elsewhere/fire-nation/a.jpg", themesDir), "");
        compare(ThemeProvider.themeFor(themesDir + "-old/fire-nation/a.jpg", themesDir), "");
    }

    function test_parseBang() {
        compare(ThemeProvider.parseBang("hello"), null);
        compare(ThemeProvider.parseBang("!gh"), null);
        compare(ThemeProvider.parseBang("!t").alias, ["theme"]);
        compare(ThemeProvider.parseBang("!wa", true).complete, false);
        compare(ThemeProvider.parseBang("!theme").alias, "theme");
        compare(ThemeProvider.parseBang("!wall Fire ", true).terms, "fire");
        compare(ThemeProvider.parseBang("!wall", false), null);
        compare(ThemeProvider.parseBang("!t", false).alias, ["theme"]);
        compare(ThemeProvider.parseBang("!wa fire", true), null);
        compare(ThemeProvider.searchItems(false).length, 1);
        compare(ThemeProvider.searchItems(true).length, 2);
    }

    function test_results() {
        var parsed = ThemeProvider.parseScan(scan, themesDir);
        var all = ThemeProvider.allThemes(parsed.themes);
        var themes = ThemeProvider.themeResults(all, parsed.wallpapers, "fire-nation", "fire");
        compare(themes.length, 1);
        compare(themes[0].subtitle, "Theme · fire effects · 2 wallpapers · current");
        compare(themes[0].thumbnail, themesDir + "/fire-nation/agni-kai.jpg");
        compare(themes[0].payload.theme, "fire-nation");

        var walls = ThemeProvider.wallpaperResults(all, parsed.wallpapers, themesDir + "/nord/fjord.webp", "");
        compare(walls[0].payload.shuffle, "fire-nation");
        compare(walls.length, 4);
        compare(walls[3].subtitle, "nord · current");
        compare(ThemeProvider.wallpaperResults(all, parsed.wallpapers, "", "fire").map(function(r) { return r.title; }),
            ["Shuffle Fire Nation", "agni kai", "ember island"]);
    }

    function test_pickRandom() {
        var parsed = ThemeProvider.parseScan(scan, themesDir);
        compare(ThemeProvider.pickRandom(parsed.wallpapers, "fire-nation", themesDir + "/fire-nation/agni-kai.jpg", 0.99),
            themesDir + "/fire-nation/zuko/ember_island.png");
        compare(ThemeProvider.pickRandom(parsed.wallpapers, "nord", themesDir + "/nord/fjord.webp", 0), "");
        compare(ThemeProvider.pickRandom(parsed.wallpapers, "dracula", "", 0), "");
    }

    function test_fileUrl() {
        compare(ThemeProvider.fileUrl("/a b/c#1.jpg"), "file:///a%20b/c%231.jpg");
        compare(ThemeProvider.fileUrl(""), "");
    }
}
