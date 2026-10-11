.pragma library
.import "../core/Config.js" as Config

// Themes: built-in color schemes, plus theme folders under ~/.config/speshell/themes,
// each holding a theme.ini and its wallpapers. See README "Themes".

var defaultTheme = "gruvbox";

var schemes = [
    { id: "gruvbox", name: "Gruvbox" },
    { id: "catppuccin-mocha", name: "Catppuccin Mocha" },
    { id: "catppuccin-macchiato", name: "Catppuccin Macchiato" },
    { id: "catppuccin-frappe", name: "Catppuccin Frappé" },
    { id: "catppuccin-latte", name: "Catppuccin Latte" },
    { id: "nord", name: "Nord" },
    { id: "dracula", name: "Dracula" },
    { id: "tokyo-night", name: "Tokyo Night" },
    { id: "rose-pine", name: "Rosé Pine" },
    { id: "solarized-dark", name: "Solarized Dark" },
    { id: "everforest", name: "Everforest" }
];

var colorKeys = [
    "base", "mantle", "crust", "surface0", "surface1", "surface2", "overlay0",
    "text", "subtext0", "subtext1", "red", "peach", "yellow", "green", "teal", "sky",
    "blue", "lavender", "mauve", "pink", "rosewater", "accent"
];

function isScheme(id) {
    return schemes.some(function(scheme) { return scheme.id === id; });
}

function fileUrl(path) {
    return path ? "file://" + String(path).split("/").map(encodeURIComponent).join("/") : "";
}

function titleFor(path) {
    var name = String(path).substring(String(path).lastIndexOf("/") + 1).replace(/\.[^.]+$/, "");
    return name.replace(/[-_]+/g, " ").trim() || name;
}

// The theme folder holding path, or "" for paths outside a theme folder.
function themeFor(path, themesDir) {
    var prefix = String(themesDir || "") + "/";
    if (themesDir === "" || String(path).indexOf(prefix) !== 0)
        return "";
    var relative = String(path).substring(prefix.length);
    var slash = relative.indexOf("/");
    return slash < 0 ? "" : relative.substring(0, slash);
}

function builtinTheme(scheme) {
    return { id: scheme.id, name: scheme.name, builtin: true, scheme: scheme.id, effects: "", colors: ({}), errors: [] };
}

// A theme folder's theme.ini text (possibly empty) as a theme. Problems are kept in
// `errors`; the theme still applies with the offending keys left out.
function parseTheme(id, text) {
    var document = Config.parseIni(text);
    var errors = document.errors.map(function(error) { return "line " + error.line + ": " + error.message; });
    function value(sectionName, key) {
        var found = Config.entry(document, sectionName, key);
        return found ? found.value : "";
    }
    var theme = {
        id: id,
        name: value("Theme", "name") || titleFor(id),
        builtin: false,
        scheme: value("Theme", "scheme") || defaultTheme,
        effects: value("Theme", "effects"),
        colors: ({}),
        errors: errors
    };
    if (!isScheme(theme.scheme)) {
        errors.push("unknown scheme '" + theme.scheme + "'");
        theme.scheme = defaultTheme;
    }
    if (theme.effects !== "" && !/^[A-Za-z0-9_-]+$/.test(theme.effects)) {
        errors.push("effects must be a folder name");
        theme.effects = "";
    }
    var colors = Config.section(document, "Colors");
    var keys = colors ? colors.keys : [];
    for (var i = 0; i < keys.length; i++) {
        var color = colors.values[keys[i]];
        if (colorKeys.indexOf(keys[i]) < 0)
            errors.push("line " + color.line + ": unknown color '" + keys[i] + "'");
        else if (!/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(color.value))
            errors.push("line " + color.line + ": " + keys[i] + " must be #rrggbb");
        else
            theme.colors[keys[i]] = color.value;
    }
    return theme;
}

// Scanner output lines: "theme<TAB>id" starts a theme folder, "ini<TAB>line" adds a
// line of its theme.ini, and "wall<TAB>path" lists a wallpaper.
function parseScan(text, themesDir) {
    var ini = ({});
    var order = [];
    var current = "";
    var paths = [];
    var lines = String(text || "").split("\n");
    for (var i = 0; i < lines.length; i++) {
        var tab = lines[i].indexOf("\t");
        if (tab < 0)
            continue;
        var kind = lines[i].substring(0, tab);
        var value = lines[i].substring(tab + 1);
        if (kind === "theme") {
            current = value;
            if (!ini.hasOwnProperty(current)) {
                ini[current] = [];
                order.push(current);
            }
        } else if (kind === "ini" && current !== "") {
            ini[current].push(value);
        } else if (kind === "wall") {
            paths.push(value);
        }
    }

    var wallpapers = [];
    for (var j = 0; j < paths.length; j++) {
        var id = themeFor(paths[j], themesDir);
        if (id === "")
            continue;
        // A folder of wallpapers is a theme even without a theme.ini.
        if (!ini.hasOwnProperty(id)) {
            ini[id] = [];
            order.push(id);
        }
        wallpapers.push({ path: paths[j], title: titleFor(paths[j]), theme: id });
    }
    wallpapers.sort(function(a, b) {
        return a.theme === b.theme ? a.title.localeCompare(b.title) : a.theme.localeCompare(b.theme);
    });
    var themes = order.map(function(id) { return parseTheme(id, ini[id].join("\n")); });
    themes.sort(function(a, b) { return a.name.localeCompare(b.name); });
    return { themes: themes, wallpapers: wallpapers };
}

// Theme folders first, then the built-in schemes they do not replace.
function allThemes(userThemes) {
    var ids = (userThemes || []).map(function(theme) { return theme.id; });
    return (userThemes || []).concat(schemes.filter(function(scheme) {
        return ids.indexOf(scheme.id) < 0;
    }).map(builtinTheme));
}

function findTheme(themes, id) {
    for (var i = 0; i < (themes || []).length; i++) {
        if (themes[i].id === id)
            return themes[i];
    }
    return null;
}

function pickRandom(wallpapers, theme, current, random) {
    var pool = (wallpapers || []).filter(function(wallpaper) {
        return wallpaper.theme === theme && wallpaper.path !== current;
    });
    if (pool.length === 0)
        return "";
    return pool[Math.min(pool.length - 1, Math.floor((random === undefined ? Math.random() : random) * pool.length))].path;
}

// ── Launcher ────────────────────────────────────────────────

var bangs = [
    { alias: "theme", title: "Themes", subtitle: "Switch the theme: colors, wallpapers, and effects", iconName: "palette" },
    { alias: "wall", title: "Wallpapers", subtitle: "Pick a wallpaper; it brings its theme along", iconName: "photo" }
];

function availableBangs(wallpapers) {
    return bangs.filter(function(bang) { return wallpapers || bang.alias !== "wall"; });
}

// null when the query is not for themes or wallpapers, otherwise
// { alias, complete, terms } for the bang typed or being typed. `wallpapers`
// offers !wall too.
function parseBang(query, wallpapers) {
    var raw = String(query || "").trim();
    if (raw.charAt(0) !== "!")
        return null;
    var body = raw.substring(1);
    var space = body.search(/\s/);
    var alias = (space < 0 ? body : body.substring(0, space)).toLowerCase();
    var offered = availableBangs(wallpapers);
    for (var i = 0; i < offered.length; i++) {
        if (alias === offered[i].alias)
            return { alias: alias, complete: true, terms: space < 0 ? "" : body.substring(space).trim().toLowerCase() };
    }
    if (space < 0 && alias !== "") {
        var partial = offered.filter(function(bang) { return bang.alias.indexOf(alias) === 0; });
        if (partial.length > 0)
            return { alias: partial.map(function(bang) { return bang.alias; }), complete: false, terms: "" };
    }
    return null;
}

function suggestion(alias) {
    var bang = bangs.filter(function(candidate) { return candidate.alias === alias; })[0];
    return {
        id: "theme:browse:" + alias,
        kind: "theme",
        title: bang.title,
        subtitle: bang.subtitle + " · Tab to complete",
        iconName: bang.iconName,
        iconSource: "",
        badge: alias.toUpperCase(),
        activatable: true,
        payload: ({}),
        completion: "!" + alias + " ",
        completeOnActivate: true
    };
}

// Searchable launcher items for plain-text queries.
function searchItems(wallpapers) {
    var items = [
        { id: "theme:browse:theme", title: "Themes", keywords: "theme color scheme palette appearance speshell", result: suggestion("theme") }
    ];
    if (wallpapers)
        items.push({ id: "theme:browse:wall", title: "Wallpapers", keywords: "wallpaper background speshell", result: suggestion("wall") });
    return items;
}

function themeResults(themes, wallpapers, currentId, terms) {
    var query = String(terms || "").toLowerCase();
    return themes.filter(function(theme) {
        return query === "" || theme.name.toLowerCase().indexOf(query) >= 0 || theme.id.indexOf(query) === 0;
    }).map(function(theme) {
        var own = wallpapers.filter(function(wallpaper) { return wallpaper.theme === theme.id; });
        var details = [theme.builtin ? "Built-in colors" : "Theme"];
        if (theme.effects !== "")
            details.push(theme.effects + " effects");
        if (own.length > 0)
            details.push(own.length === 1 ? "1 wallpaper" : own.length + " wallpapers");
        if (theme.id === currentId)
            details.push("current");
        return {
            id: "theme:" + theme.id,
            kind: "theme",
            title: theme.name,
            subtitle: details.join(" · "),
            iconName: "palette",
            iconSource: "",
            thumbnail: own.length > 0 ? own[0].path : "",
            badge: "THEME",
            activatable: true,
            payload: { theme: theme.id }
        };
    });
}

function wallpaperResults(themes, wallpapers, current, terms) {
    var query = String(terms || "").toLowerCase();
    var counts = ({});
    var shuffleRows = [];
    var rows = [];
    function themeName(id) {
        var theme = findTheme(themes, id);
        return theme ? theme.name : id;
    }
    for (var i = 0; i < wallpapers.length; i++) {
        var wallpaper = wallpapers[i];
        var name = themeName(wallpaper.theme);
        counts[wallpaper.theme] = (counts[wallpaper.theme] || 0) + 1;
        if (query !== "" && wallpaper.title.toLowerCase().indexOf(query) < 0
                && name.toLowerCase().indexOf(query) < 0)
            continue;
        rows.push({
            id: "wallpaper:" + wallpaper.path,
            kind: "theme",
            title: wallpaper.title,
            subtitle: name + (wallpaper.path === current ? " · current" : ""),
            iconName: "photo",
            iconSource: "",
            thumbnail: wallpaper.path,
            badge: "WALL",
            activatable: true,
            payload: { path: wallpaper.path }
        });
    }
    var ids = Object.keys(counts).sort();
    for (var j = 0; j < ids.length; j++) {
        var label = themeName(ids[j]);
        if (counts[ids[j]] < 2 || (query !== "" && label.toLowerCase().indexOf(query) < 0))
            continue;
        shuffleRows.push({
            id: "wallpaper:shuffle:" + ids[j],
            kind: "theme",
            title: "Shuffle " + label,
            subtitle: counts[ids[j]] + " wallpapers · picks one at random",
            iconName: "shuffle",
            iconSource: "",
            badge: "WALL",
            activatable: true,
            payload: { shuffle: ids[j] }
        });
    }
    return shuffleRows.concat(rows);
}
