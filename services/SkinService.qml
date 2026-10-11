pragma Singleton
import QtQuick
import Quickshell
import "." as AppServices

// Loads an optional skin: a directory whose Skin.qml may provide a palette, an
// accent color, and launcher and wallpaper transitions. See README "Skins".
Singleton {
    id: root

    readonly property int apiVersion: 1

    // Skin name under <dataDir>/skins, chosen by the wallpaper's folder. "" disables skins.
    property string skin: ""
    readonly property string skinDir: root.skin !== "" && AppServices.ConfigService.dataDir !== ""
        ? AppServices.ConfigService.dataDir + "/skins/" + root.skin
        : ""

    property var current: null
    property string error: ""

    readonly property var palette: root.current && root.current.palette ? root.current.palette : null
    readonly property string accent: root.current && root.current.accent ? String(root.current.accent) : ""
    readonly property Component launcherTransition: root.current && root.current.launcherTransition
        ? root.current.launcherTransition
        : null
    readonly property Component wallpaperTransition: root.current && root.current.wallpaperTransition
        ? root.current.wallpaperTransition
        : null

    // A transition from the old skin may still be playing, for example the launcher
    // exit after picking a wallpaper, so the old skin outlives its replacement briefly.
    function unload() {
        if (root.current)
            root.current.destroy(5000);
        root.current = null;
    }

    function fail(message) {
        root.error = message;
        AppServices.NotificationService.addInternalNotification("skin", "Skin unavailable", message);
    }

    function declaredApi(skinObject) {
        return skinObject.apiVersion;
    }

    function load() {
        root.unload();
        root.error = "";
        if (root.skinDir === "")
            return;

        var component = Qt.createComponent("file://" + root.skinDir + "/Skin.qml");
        if (component.status !== Component.Ready) {
            root.fail("Could not load skin '" + root.skin + "': " + component.errorString().trim());
            return;
        }
        var skinObject = component.createObject(root);
        if (!skinObject) {
            root.fail("Could not create skin '" + root.skin + "'.");
            return;
        }
        var skinApi = root.declaredApi(skinObject);
        if (skinApi !== root.apiVersion) {
            skinObject.destroy();
            root.fail("Skin '" + root.skin + "' targets skin API " + skinApi
                + "; this Speshell supports " + root.apiVersion + ".");
            return;
        }
        root.current = skinObject;
    }

    // Load synchronously so a wallpaper change sees its new skin's transition.
    onSkinDirChanged: root.load()
}
