.pragma library

var bang = "wall";

function fileUrl(path) {
    return path ? "file://" + String(path).split("/").map(encodeURIComponent).join("/") : "";
}

function titleFor(path) {
    var name = String(path).substring(String(path).lastIndexOf("/") + 1).replace(/\.[^.]+$/, "");
    return name.replace(/[-_]+/g, " ").trim() || name;
}

// The library's top-level folder holding path, or "" for loose files and paths
// outside the library.
function folderFor(path, libraryDir) {
    var prefix = String(libraryDir || "") + "/";
    if (libraryDir === "" || String(path).indexOf(prefix) !== 0)
        return "";
    var relative = String(path).substring(prefix.length);
    var slash = relative.indexOf("/");
    return slash < 0 ? "" : relative.substring(0, slash);
}

// A wallpaper applies the skin its top-level folder is named after, when installed.
function skinFor(path, libraryDir, skins) {
    var folder = folderFor(path, libraryDir);
    return folder !== "" && (skins || []).indexOf(folder) >= 0 ? folder : "";
}

// Scanner output lines are "skin<TAB>name" or "wall<TAB>path".
function parseScan(text, libraryDir) {
    var skins = [];
    var paths = [];
    var lines = String(text || "").split("\n");
    for (var i = 0; i < lines.length; i++) {
        var tab = lines[i].indexOf("\t");
        if (tab < 0)
            continue;
        var kind = lines[i].substring(0, tab);
        var value = lines[i].substring(tab + 1);
        if (kind === "skin" && skins.indexOf(value) < 0)
            skins.push(value);
        else if (kind === "wall")
            paths.push(value);
    }
    var wallpapers = paths.map(function(path) {
        return { path: path, title: titleFor(path), folder: folderFor(path, libraryDir) };
    });
    wallpapers.sort(function(a, b) {
        return a.folder === b.folder ? a.title.localeCompare(b.title) : a.folder.localeCompare(b.folder);
    });
    return { skins: skins.sort(), wallpapers: wallpapers };
}

function pickRandom(wallpapers, folder, current, random) {
    var pool = (wallpapers || []).filter(function(wallpaper) {
        return (folder === undefined || wallpaper.folder === folder) && wallpaper.path !== current;
    });
    if (pool.length === 0)
        return "";
    return pool[Math.min(pool.length - 1, Math.floor((random === undefined ? Math.random() : random) * pool.length))].path;
}

// null when the query is not for wallpapers, otherwise { complete, terms }.
function parseBang(query) {
    var raw = String(query || "").trim();
    if (raw.charAt(0) !== "!")
        return null;
    var body = raw.substring(1);
    var space = body.search(/\s/);
    var alias = (space < 0 ? body : body.substring(0, space)).toLowerCase();
    if (alias === bang)
        return { complete: true, terms: space < 0 ? "" : body.substring(space).trim().toLowerCase() };
    if (space < 0 && bang.indexOf(alias) === 0)
        return { complete: false, terms: "" };
    return null;
}

function suggestion() {
    return {
        id: "wallpaper:browse",
        kind: "wallpaper",
        title: "Wallpapers",
        subtitle: "Pick a wallpaper; its folder picks the skin · Tab to complete",
        iconName: "photo",
        iconSource: "",
        badge: "WALL",
        activatable: true,
        payload: ({}),
        completion: "!" + bang + " ",
        completeOnActivate: true
    };
}

// Searchable launcher item for plain-text queries.
function searchItems() {
    return [{
        id: "wallpaper:browse",
        title: "Wallpapers",
        keywords: "wallpaper background skin theme speshell",
        result: suggestion()
    }];
}

function results(wallpapers, skins, current, terms) {
    var query = String(terms || "").toLowerCase();
    var counts = ({});
    var rows = [];
    var wallpaperRows = [];
    for (var i = 0; i < wallpapers.length; i++) {
        var wallpaper = wallpapers[i];
        counts[wallpaper.folder] = (counts[wallpaper.folder] || 0) + 1;
        if (query !== "" && wallpaper.title.toLowerCase().indexOf(query) < 0
                && wallpaper.folder.toLowerCase().indexOf(query) !== 0)
            continue;
        var skin = skins.indexOf(wallpaper.folder) >= 0 ? wallpaper.folder : "";
        wallpaperRows.push({
            id: "wallpaper:" + wallpaper.path,
            kind: "wallpaper",
            title: wallpaper.title,
            subtitle: (skin !== "" ? skin + " skin" : (wallpaper.folder || "No skin"))
                + (wallpaper.path === current ? " · current" : ""),
            iconName: "photo",
            iconSource: "",
            thumbnail: wallpaper.path,
            badge: "WALL",
            activatable: true,
            payload: { path: wallpaper.path }
        });
    }
    var folders = Object.keys(counts).sort();
    for (var j = 0; j < folders.length; j++) {
        if (folders[j] === "" || counts[folders[j]] < 2
                || (query !== "" && folders[j].toLowerCase().indexOf(query) !== 0))
            continue;
        rows.push({
            id: "wallpaper:shuffle:" + folders[j],
            kind: "wallpaper",
            title: "Shuffle " + folders[j],
            subtitle: counts[folders[j]] + " wallpapers · picks one at random",
            iconName: "shuffle",
            iconSource: "",
            badge: "WALL",
            activatable: true,
            payload: { folder: folders[j] }
        });
    }
    return rows.concat(wallpaperRows);
}
