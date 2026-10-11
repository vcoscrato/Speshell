import QtQuick
import QtTest
import "../services/ThemeProvider.js" as ThemeProvider

TestCase {
    name: "ThemeProvider"

    readonly property string shippedDir: "/usr/share/speshell/extras/themes"
    readonly property string themesDir: "/home/me/.config/speshell/themes"
    readonly property var themesDirs: [shippedDir, themesDir]
    readonly property string scan: [
        "theme\t" + shippedDir + "/fire",
        "ini\t[Theme]",
        "ini\tname = Fire",
        "ini\teffects = fire",
        "ini\t[Colors]",
        "ini\taccent = #e5482e",
        "ini\tbase = #1d1416",
        "theme\t" + shippedDir + "/cosmos",
        "ini\t[Theme]",
        "ini\tname = Cosmos",
        "ini\teffects = cosmos",
        "theme\t" + themesDir + "/broken",
        "ini\t[Theme]",
        "ini\teffects = smoke",
        "ini\t[Colors]",
        "ini\ttext = white",
        "ini\tglow = #ffffff",
        "theme\t" + themesDir + "/cosmos",
        "ini\t[Theme]",
        "ini\tname = My Cosmos",
        "wall\t" + shippedDir + "/fire/agni-kai.jpg",
        "wall\t" + shippedDir + "/cosmos/galaxy.jpg",
        "wall\t" + themesDir + "/fire/zuko/ember_island.png",
        "wall\t" + themesDir + "/cosmos/galaxy.jpg",
        "wall\t" + themesDir + "/nord/fjord.webp",
        "wall\t" + themesDir + "/loose.jpg",
        "effects\t/usr/share/speshell/extras/effects/fire",
        "effects\t/usr/share/speshell/extras/effects/cosmos",
        "effects\t/home/me/.local/share/speshell/effects/fire",
        ""
    ].join("\n")

    function test_parseScan() {
        var parsed = ThemeProvider.parseScan(scan, themesDirs);
        compare(parsed.themes.map(function(t) { return t.id; }), ["broken", "fire", "cosmos", "nord"]);
        var fire = ThemeProvider.findTheme(parsed.themes, "fire");
        compare(fire.name, "Fire");
        compare(fire.effects, "fire");
        // The user's effects directory replaces the shipped one of the same name.
        compare(fire.effectsDir, "/home/me/.local/share/speshell/effects/fire");
        compare(fire.colors.accent, "#e5482e");
        compare(fire.colors.base, "#1d1416");
        compare(fire.errors.length, 0);
        compare(parsed.wallpapers.map(function(w) { return w.theme; }), ["cosmos", "fire", "fire", "nord"]);
        compare(parsed.wallpapers[2].title, "ember island");
    }

    function test_userOverrides() {
        var parsed = ThemeProvider.parseScan(scan, themesDirs);
        // The user's theme.ini replaces the shipped one, keys and all.
        var cosmos = ThemeProvider.findTheme(parsed.themes, "cosmos");
        compare(cosmos.name, "My Cosmos");
        compare(cosmos.effects, "");
        // Wallpapers from both folders add up; the user's copy replaces the shipped one.
        compare(parsed.wallpapers.filter(function(w) { return w.theme === "fire"; }).length, 2);
        compare(parsed.wallpapers[0].path, themesDir + "/cosmos/galaxy.jpg");
    }

    function test_parseTheme_errors() {
        var broken = ThemeProvider.findTheme(ThemeProvider.parseScan(scan, themesDirs).themes, "broken");
        compare(broken.effects, "smoke");
        compare(broken.effectsDir, "");
        compare(broken.colors, ({}));
        compare(broken.errors.length, 3);
        verify(broken.errors[0].indexOf("effects 'smoke' are not installed") >= 0);
        compare(ThemeProvider.parseTheme("x", "[Theme]\neffects = ../fire").effects, "");
    }

    function test_folderWithoutIni() {
        var nord = ThemeProvider.findTheme(ThemeProvider.parseScan(scan, themesDirs).themes, "nord");
        compare(nord.name, "nord");
        compare(nord.colors, ({}));
        compare(nord.effectsDir, "");
    }

    function test_allThemes() {
        var parsed = ThemeProvider.parseScan(scan, themesDirs);
        compare(ThemeProvider.allThemes(parsed.themes).length, 4);
        // Cosmos stands in when no folder provides it.
        var none = ThemeProvider.allThemes([]);
        compare(none.length, 1);
        compare(none[0].id, ThemeProvider.defaultTheme);
        compare(ThemeProvider.defaultTheme, "cosmos");
    }

    function test_themeFor() {
        compare(ThemeProvider.themeFor(themesDir + "/fire/zuko/a.png", themesDirs), "fire");
        compare(ThemeProvider.themeFor(shippedDir + "/cosmos/galaxy.jpg", themesDirs), "cosmos");
        compare(ThemeProvider.themeFor(themesDir + "/loose.jpg", themesDirs), "");
        compare(ThemeProvider.themeFor("/elsewhere/fire/a.jpg", themesDirs), "");
        compare(ThemeProvider.themeFor(themesDir + "-old/fire/a.jpg", themesDirs), "");
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
        var parsed = ThemeProvider.parseScan(scan, themesDirs);
        var all = ThemeProvider.allThemes(parsed.themes);
        var themes = ThemeProvider.themeResults(all, parsed.wallpapers, "fire", "fire");
        compare(themes.length, 1);
        compare(themes[0].subtitle, "Theme · fire effects · 2 wallpapers · current");
        compare(themes[0].thumbnail, shippedDir + "/fire/agni-kai.jpg");
        compare(themes[0].payload.theme, "fire");
        var chosen = { "fire": themesDir + "/fire/zuko/ember_island.png" };
        compare(ThemeProvider.themeResults(all, parsed.wallpapers, "", "fire", chosen)[0].thumbnail, chosen["fire"]);

        var walls = ThemeProvider.wallpaperResults(all, parsed.wallpapers, themesDir + "/nord/fjord.webp", "");
        compare(walls[0].payload.shuffle, "fire");
        compare(walls.length, 5);
        compare(walls[4].subtitle, "nord · current");
        compare(ThemeProvider.wallpaperResults(all, parsed.wallpapers, "", "fire").map(function(r) { return r.title; }),
            ["Shuffle Fire", "agni kai", "ember island"]);
    }

    function test_pickRandom() {
        var parsed = ThemeProvider.parseScan(scan, themesDirs);
        compare(ThemeProvider.pickRandom(parsed.wallpapers, "fire", shippedDir + "/fire/agni-kai.jpg", 0.99),
            themesDir + "/fire/zuko/ember_island.png");
        compare(ThemeProvider.pickRandom(parsed.wallpapers, "nord", themesDir + "/nord/fjord.webp", 0), "");
        compare(ThemeProvider.pickRandom(parsed.wallpapers, "broken", "", 0), "");
    }

    function test_themeWallpaper() {
        var parsed = ThemeProvider.parseScan(scan, themesDirs);
        var island = themesDir + "/fire/zuko/ember_island.png";
        compare(ThemeProvider.themeWallpaper(parsed.wallpapers, "fire", ({})), shippedDir + "/fire/agni-kai.jpg");
        compare(ThemeProvider.themeWallpaper(parsed.wallpapers, "fire", { "fire": island }), island);
        // A remembered wallpaper that is gone, or belongs to another theme, falls back.
        compare(ThemeProvider.themeWallpaper(parsed.wallpapers, "fire", { "fire": "/gone.jpg" }),
            shippedDir + "/fire/agni-kai.jpg");
        compare(ThemeProvider.themeWallpaper(parsed.wallpapers, "nord", { "nord": island }), themesDir + "/nord/fjord.webp");
        compare(ThemeProvider.themeWallpaper(parsed.wallpapers, "broken", undefined), "");
    }

    function test_pickRandomTheme() {
        var themes = [{ id: "a" }, { id: "b" }, { id: "c" }];
        compare(ThemeProvider.pickRandomTheme(themes, "a", 0), "b");
        compare(ThemeProvider.pickRandomTheme(themes, "a", 0.99), "c");
        compare(ThemeProvider.pickRandomTheme([{ id: "a" }], "a", 0.5), "");
    }

    function test_fileUrl() {
        compare(ThemeProvider.fileUrl("/a b/c#1.jpg"), "file:///a%20b/c%231.jpg");
        compare(ThemeProvider.fileUrl(""), "");
    }
}
