pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "." as AppServices
import "WallpaperProvider.js" as WallpaperProvider

// Wallpaper library and the current wallpaper. A wallpaper inside a top-level
// folder named after an installed skin applies that skin. See README "Wallpapers".
Singleton {
    id: root

    // Library directory from config: absolute or ~/-relative. "" disables wallpapers.
    property string directory: ""
    readonly property string libraryDir: {
        var dir = root.directory.replace(/\/+$/, "");
        return dir.indexOf("~/") === 0 ? Quickshell.env("HOME") + dir.substring(1) : dir;
    }
    readonly property bool enabled: root.libraryDir !== ""
    readonly property string skinsDir: AppServices.ConfigService.dataDir !== ""
        ? AppServices.ConfigService.dataDir + "/skins"
        : ""
    readonly property string statePath: AppServices.ConfigService.dataDir !== ""
        ? AppServices.ConfigService.dataDir + "/wallpaper.json"
        : ""

    property var wallpapers: []
    property var skins: []
    property bool scanned: false
    property bool stateLoaded: false
    property bool saving: false
    property bool saveQueued: false
    property string current: ""
    readonly property string skin: root.enabled
        ? WallpaperProvider.skinFor(root.current, root.libraryDir, root.skins)
        : ""

    function set(path) {
        var next = String(path || "");
        if (!root.enabled || next === "" || next === root.current)
            return;
        root.current = next;
        root.save();
    }

    // FileView drops a write that starts while another is in flight, so queue it.
    function save() {
        if (root.statePath === "")
            return;
        if (root.saving) {
            root.saveQueued = true;
            return;
        }
        root.saving = true;
        stateFile.setText(JSON.stringify({ current: root.current }));
    }

    function finishSave() {
        root.saving = false;
        if (root.saveQueued) {
            root.saveQueued = false;
            root.save();
        }
    }

    // Random wallpaper from a top-level folder ("" for loose files), or from the whole library.
    function shuffle(folder) {
        root.set(WallpaperProvider.pickRandom(root.wallpapers, folder, root.current));
    }

    function scan() {
        if (!root.enabled)
            return;
        if (scanProc.running) {
            scanProc.queued = true;
            return;
        }
        scanProc.command = [
            "sh", "-c",
            "[ -d \"$2\" ] && find -L \"$2\" -mindepth 2 -maxdepth 2 -name Skin.qml -printf 'skin\\t%h\\n' "
                + "| sed 's|\\t.*/|\\t|'; "
                + "find -L \"$1\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' "
                + "-o -iname '*.webp' \\) -printf 'wall\\t%p\\n'",
            "speshell-wallpaper-scan",
            root.libraryDir,
            root.skinsDir
        ];
        scanProc.running = true;
    }

    function finishScan(text) {
        var library = WallpaperProvider.parseScan(text, root.libraryDir);
        root.skins = library.skins;
        root.wallpapers = library.wallpapers;
        root.scanned = true;
        root.pickFirst();
    }

    // First run: start from a random wallpaper instead of a bare background.
    function pickFirst() {
        if (root.scanned && root.stateLoaded && root.current === "")
            root.shuffle(undefined);
    }

    function finishStateLoad(text) {
        var parsed = ({});
        try {
            parsed = JSON.parse(text || "{}");
        } catch (stateError) {
            parsed = ({});
        }
        if (root.current === "" && parsed && typeof parsed.current === "string")
            root.current = parsed.current;
        root.stateLoaded = true;
        root.pickFirst();
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
        printErrors: false
        onLoaded: root.finishStateLoad(stateFile.text())
        onLoadFailed: root.finishStateLoad("{}")
        onSaved: root.finishSave()
        onSaveFailed: root.finishSave()
    }

    onLibraryDirChanged: {
        root.scanned = false;
        root.wallpapers = [];
        root.scan();
    }
    onSkinsDirChanged: root.scan()
}
