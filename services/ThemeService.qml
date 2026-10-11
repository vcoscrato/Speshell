pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "." as AppServices
import "ThemeProvider.js" as ThemeProvider

// The active theme and its wallpaper. Themes are folders holding a theme.ini and
// wallpapers, shipped under extras/themes and added under <configDir>/themes;
// picking a wallpaper applies its folder's theme. See README "Themes".
Singleton {
    id: root

    readonly property string shippedThemesDir: Quickshell.shellDir + "/extras/themes"
    readonly property string shippedEffectsDir: Quickshell.shellDir + "/extras/effects"
    readonly property string themesDir: AppServices.ConfigService.configDir !== ""
        ? AppServices.ConfigService.configDir + "/themes"
        : ""
    readonly property string userEffectsDir: AppServices.ConfigService.dataDir !== ""
        ? AppServices.ConfigService.dataDir + "/effects"
        : ""
    // User folders come last, so they override shipped ones of the same name.
    readonly property var themesDirs: [root.shippedThemesDir, root.themesDir]
    readonly property string statePath: AppServices.ConfigService.dataDir !== ""
        ? AppServices.ConfigService.dataDir + "/theme.json"
        : ""

    property var folderThemes: []
    property var wallpapers: []
    property bool scanned: false
    readonly property bool scanning: scanProc.running
    property bool stateLoaded: false
    property bool saving: false
    property bool saveQueued: false
    property string reported: ""

    property string themeId: ThemeProvider.defaultTheme
    property string wallpaper: ""
    // The last applied theme, saved with the selection so startup can apply it
    // before the scan finishes.
    property var snapshot: null

    readonly property var themes: ThemeProvider.allThemes(root.folderThemes)
    readonly property var theme: {
        if (!root.scanned && root.snapshot && root.snapshot.id === root.themeId)
            return root.snapshot;
        return ThemeProvider.findTheme(root.themes, root.themeId)
            || ThemeProvider.findTheme(root.themes, ThemeProvider.defaultTheme);
    }
    readonly property var colors: root.theme.colors
    // The active theme's effects directory, "" for none.
    readonly property string activeEffectsDir: root.theme.effectsDir || ""
    // [Appearance] drawWallpaper: Speshell draws the desktop background, showing
    // the default wallpaper for themes without their own. Off by default so other
    // wallpaper tools keep working; themes still set colors and effects.
    property bool wallpaperEnabled: false

    function setTheme(id) {
        if (!ThemeProvider.findTheme(root.themes, id))
            return false;
        if (id !== root.themeId) {
            root.themeId = id;
            root.wallpaper = ThemeProvider.pickRandom(root.wallpapers, id, "");
            root.save();
        }
        return true;
    }

    // A wallpaper brings its theme along.
    function setWallpaper(path) {
        var next = String(path || "");
        var id = ThemeProvider.themeFor(next, root.themesDirs);
        if (!root.wallpaperEnabled || id === "")
            return false;
        if (next !== root.wallpaper || id !== root.themeId) {
            root.themeId = id;
            root.wallpaper = next;
            root.save();
        }
        if (!ThemeProvider.findTheme(root.folderThemes, id))
            root.scan();
        return true;
    }

    // A random wallpaper of a theme, the current one by default.
    function shuffle(id) {
        var next = ThemeProvider.pickRandom(root.wallpapers, id || root.themeId, root.wallpaper);
        return next !== "" && root.setWallpaper(next);
    }

    function save() {
        if (root.statePath === "")
            return;
        // FileView drops a write that starts while another is in flight, so queue it.
        if (root.saving) {
            root.saveQueued = true;
            return;
        }
        var theme = root.theme;
        root.snapshot = { id: theme.id, name: theme.name, effects: theme.effects, effectsDir: theme.effectsDir,
                          colors: theme.colors, errors: [] };
        root.saving = true;
        stateFile.setText(JSON.stringify({ theme: root.themeId, wallpaper: root.wallpaper, snapshot: root.snapshot }));
    }

    function finishSave() {
        root.saving = false;
        if (root.saveQueued) {
            root.saveQueued = false;
            root.save();
        }
    }

    function finishStateLoad(text) {
        var parsed = ({});
        try {
            parsed = JSON.parse(text || "{}");
        } catch (stateError) {
            parsed = ({});
        }
        if (parsed && typeof parsed.theme === "string" && parsed.theme !== "") {
            root.snapshot = parsed.snapshot && parsed.snapshot.colors ? parsed.snapshot : null;
            root.themeId = parsed.theme;
            root.wallpaper = typeof parsed.wallpaper === "string" ? parsed.wallpaper : "";
        }
        root.stateLoaded = true;
        root.reconcile();
    }

    function scan() {
        if (scanProc.running) {
            scanProc.queued = true;
            return;
        }
        scanProc.command = [
            "sh", "-c",
            "for dir in \"$1\" \"$2\"; do [ -d \"$dir\" ] || continue; "
                + "for f in \"$dir\"/*/theme.ini; do [ -f \"$f\" ] || continue; "
                + "printf 'theme\\t%s\\n' \"${f%/theme.ini}\"; awk '{ print \"ini\\t\" $0 }' \"$f\"; done; "
                + "find -L \"$dir\" -mindepth 2 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' "
                + "-o -iname '*.png' -o -iname '*.webp' \\) -printf 'wall\\t%p\\n'; done; "
                + "for dir in \"$3\" \"$4\"; do [ -d \"$dir\" ] || continue; for f in \"$dir\"/*/Effects.qml; do "
                + "[ -f \"$f\" ] && printf 'effects\\t%s\\n' \"${f%/Effects.qml}\"; done; done; true",
            "speshell-theme-scan",
            root.shippedThemesDir,
            root.themesDir,
            root.shippedEffectsDir,
            root.userEffectsDir
        ];
        scanProc.running = true;
    }

    function finishScan(text) {
        var library = ThemeProvider.parseScan(text, root.themesDirs);
        root.folderThemes = library.themes;
        root.wallpapers = library.wallpapers;
        root.scanned = true;
        root.reconcile();
    }

    function reconcile() {
        if (!root.scanned || !root.stateLoaded)
            return;
        var before = root.themeId + "\n" + root.wallpaper;
        // The selection may have gone stale: a removed theme or wallpaper.
        if (!ThemeProvider.findTheme(root.themes, root.themeId)) {
            root.themeId = ThemeProvider.defaultTheme;
            root.wallpaper = "";
        }
        var own = root.wallpapers.filter(function(wallpaper) {
            return wallpaper.theme === root.themeId && wallpaper.path === root.wallpaper;
        });
        if (own.length === 0)
            root.wallpaper = ThemeProvider.pickRandom(root.wallpapers, root.themeId, "");
        // Keep the saved snapshot in step with edits to theme.ini.
        if (before !== root.themeId + "\n" + root.wallpaper || !root.snapshot || JSON.stringify(root.snapshot.colors) !== JSON.stringify(root.theme.colors)
                || root.snapshot.effectsDir !== root.theme.effectsDir || root.snapshot.effects !== root.theme.effects
                || root.snapshot.id !== root.themeId)
            root.save();
        root.report();
    }

    // Tell the user once about problems in the active theme's theme.ini.
    function report() {
        var theme = root.theme;
        var key = theme.id + "\n" + theme.errors.join("\n");
        if (theme.errors.length === 0 || key === root.reported)
            return;
        root.reported = key;
        AppServices.NotificationService.addInternalNotification("theme", "Problems in theme '" + theme.name + "'",
            theme.errors.join("\n"));
    }

    Process {
        id: scanProc
        property bool queued: false
        stdout: StdioCollector {
            id: scanOutput
        }
        onExited: {
            root.finishScan(scanOutput.text);
            if (scanProc.queued) {
                scanProc.queued = false;
                root.scan();
            }
        }
    }

    FileView {
        id: stateFile
        path: root.statePath
        atomicWrites: true
        blockLoading: true
        printErrors: false
        onLoaded: root.finishStateLoad(stateFile.text())
        onLoadFailed: root.finishStateLoad("{}")
        onSaved: root.finishSave()
        onSaveFailed: root.finishSave()
    }

    onThemeIdChanged: root.report()
    onThemesDirChanged: root.scan()
    onUserEffectsDirChanged: root.scan()
    // The folder may already be known when the service is first used.
    Component.onCompleted: root.scan()
}
