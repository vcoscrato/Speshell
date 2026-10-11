import QtQuick
import QtTest
import "../services/WallpaperProvider.js" as WallpaperProvider

TestCase {
    name: "WallpaperProvider"

    readonly property string library: "/home/me/Wallpapers"
    readonly property string scan: [
        "skin\tfire",
        "skin\tair",
        "wall\t/home/me/Wallpapers/fire/agni-kai.jpg",
        "wall\t/home/me/Wallpapers/fire/zuko/ember_island.png",
        "wall\t/home/me/Wallpapers/air/western-air-temple.jpg",
        "wall\t/home/me/Wallpapers/nature/forest.webp",
        "wall\t/home/me/Wallpapers/loose.jpg",
        ""
    ].join("\n")

    function test_parseScan() {
        var parsed = WallpaperProvider.parseScan(scan, library);
        compare(parsed.skins, ["air", "fire"]);
        compare(parsed.wallpapers.map(function(w) { return w.folder; }), ["", "air", "fire", "fire", "nature"]);
        compare(parsed.wallpapers[2].title, "agni kai");
        compare(parsed.wallpapers[3].title, "ember island");
    }

    function test_skinFor() {
        var skins = ["air", "fire"];
        compare(WallpaperProvider.skinFor(library + "/fire/zuko/ember_island.png", library, skins), "fire");
        compare(WallpaperProvider.skinFor(library + "/nature/forest.webp", library, skins), "");
        compare(WallpaperProvider.skinFor(library + "/loose.jpg", library, skins), "");
        compare(WallpaperProvider.skinFor("/elsewhere/fire/a.jpg", library, skins), "");
        compare(WallpaperProvider.skinFor(library + "-old/fire/a.jpg", library, skins), "");
    }

    function test_parseBang() {
        compare(WallpaperProvider.parseBang("hello"), null);
        compare(WallpaperProvider.parseBang("!gh"), null);
        compare(WallpaperProvider.parseBang("!wa").complete, false);
        compare(WallpaperProvider.parseBang("!wall").complete, true);
        compare(WallpaperProvider.parseBang("!wall Fire ").terms, "fire");
        compare(WallpaperProvider.parseBang("!wa fire"), null);
    }

    function test_results() {
        var parsed = WallpaperProvider.parseScan(scan, library);
        var all = WallpaperProvider.results(parsed.wallpapers, parsed.skins, library + "/air/western-air-temple.jpg", "");
        compare(all[0].id, "wallpaper:shuffle:fire");
        compare(all[0].payload.folder, "fire");
        compare(all.length, 6);
        var air = all.filter(function(r) { return r.payload.path === library + "/air/western-air-temple.jpg"; })[0];
        compare(air.subtitle, "air skin · current");
        compare(air.thumbnail, library + "/air/western-air-temple.jpg");

        var fire = WallpaperProvider.results(parsed.wallpapers, parsed.skins, "", "fi");
        compare(fire.map(function(r) { return r.title; }), ["Shuffle fire", "agni kai", "ember island"]);
        compare(WallpaperProvider.results(parsed.wallpapers, parsed.skins, "", "forest")[0].subtitle, "nature");
    }

    function test_pickRandom() {
        var parsed = WallpaperProvider.parseScan(scan, library);
        compare(WallpaperProvider.pickRandom(parsed.wallpapers, "fire", library + "/fire/agni-kai.jpg", 0.99),
            library + "/fire/zuko/ember_island.png");
        compare(WallpaperProvider.pickRandom(parsed.wallpapers, "air", library + "/air/western-air-temple.jpg", 0), "");
        compare(WallpaperProvider.pickRandom(parsed.wallpapers, undefined, "", 0), library + "/loose.jpg");
    }

    function test_fileUrl() {
        compare(WallpaperProvider.fileUrl("/a b/c#1.jpg"), "file:///a%20b/c%231.jpg");
        compare(WallpaperProvider.fileUrl(""), "");
    }
}
