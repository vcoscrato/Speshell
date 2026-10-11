pragma Singleton
import QtQuick
import Quickshell
import "." as AppServices

// Loads the active theme's effects: a directory under <dataDir>/effects whose
// Effects.qml may provide launcher and wallpaper transitions. See README "Effects".
Singleton {
    id: root

    readonly property int apiVersion: 1

    // Effects name, from the active theme. "" disables effects.
    property string name: ""
    readonly property string dir: root.name !== "" && AppServices.ConfigService.dataDir !== ""
        ? AppServices.ConfigService.dataDir + "/effects/" + root.name
        : ""

    property var current: null
    property string error: ""

    readonly property Component launcherTransition: root.current && root.current.launcherTransition
        ? root.current.launcherTransition
        : null
    readonly property Component wallpaperTransition: root.current && root.current.wallpaperTransition
        ? root.current.wallpaperTransition
        : null

    // A transition from the old effects may still be playing, for example the launcher
    // exit after picking a theme, so the old effects outlive their replacement briefly.
    function unload() {
        if (root.current)
            root.current.destroy(5000);
        root.current = null;
    }

    function fail(message) {
        root.error = message;
        AppServices.NotificationService.addInternalNotification("effects", "Effects unavailable", message);
    }

    function declaredApi(effectsObject) {
        return effectsObject.apiVersion;
    }

    function load() {
        root.unload();
        root.error = "";
        if (root.dir === "")
            return;

        var component = Qt.createComponent("file://" + root.dir + "/Effects.qml");
        if (component.status !== Component.Ready) {
            root.fail("Could not load effects '" + root.name + "': " + component.errorString().trim());
            return;
        }
        var effectsObject = component.createObject(root);
        if (!effectsObject) {
            root.fail("Could not create effects '" + root.name + "'.");
            return;
        }
        var effectsApi = root.declaredApi(effectsObject);
        if (effectsApi !== root.apiVersion) {
            effectsObject.destroy();
            root.fail("Effects '" + root.name + "' target effects API " + effectsApi
                + "; this Speshell supports " + root.apiVersion + ".");
            return;
        }
        root.current = effectsObject;
    }

    // Load synchronously so a wallpaper change sees its new effects' transition.
    onDirChanged: root.load()
}
