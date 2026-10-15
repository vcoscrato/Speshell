pragma Singleton
import QtQuick
import Quickshell
import "." as AppServices

// Loads the active theme's effects: a directory, shipped under extras/effects or
// added under <dataDir>/effects, whose Effects.qml may provide launcher, wallpaper,
// and dashboard transitions, a dashboard backdrop, effects on the dashboard's controls,
// and a knob for its sliders and switches. See extras/effects/README.md.
Singleton {
    id: root

    readonly property int apiVersion: 1

    // Effects directory, from the active theme. "" disables effects.
    property string dir: ""
    readonly property string name: root.dir.substring(root.dir.lastIndexOf("/") + 1)

    property var current: null
    property string error: ""

    // Transition speeds from config, one per surface: a multiple of normal speed; 0
    // turns that surface's transitions off. Hosts pass them on as `timeScale`, which
    // EffectClock follows.
    property real launcherSpeed: 1
    property real dashboardSpeed: 1
    property real wallpaperSpeed: 1
    readonly property bool transitionsEnabled: root.launcherSpeed > 0 || root.dashboardSpeed > 0
        || root.wallpaperSpeed > 0
    // Frames per second of transitions from config, passed on as `frameRate`.
    property int frameRate: 60

    readonly property Component launcherTransition: root.launcherSpeed > 0 && root.current
        && root.current.launcherTransition ? root.current.launcherTransition : null
    readonly property Component wallpaperTransition: root.wallpaperSpeed > 0 && root.current
        && root.current.wallpaperTransition ? root.current.wallpaperTransition : null
    readonly property Component dashboardTransition: root.dashboardSpeed > 0
        ? root.optional("dashboardTransition") : null
    // Still, so it stays with transitions off.
    readonly property Component dashboardBackdrop: root.optional("dashboardBackdrop")
    readonly property Component dashboardInteractions: root.dashboardSpeed > 0
        ? root.optional("dashboardInteractions") : null
    // The thumb of sliders and switches; moved only by the hand, so it stays too.
    readonly property Component knob: root.optional("knob")

    // Controls report the user's hand on them here; the dashboard passes these on to
    // the effects' interactions. `knob` is the thumb that moved `dx` px or was let go,
    // `target` what was picked, `pointer` the MouseArea clicked to pick it (null from the
    // keyboard), and `control` the switch turned on or off.
    signal knobMoved(Item knob, real dx)
    signal knobReleased(Item knob)
    signal picked(Item target, Item pointer)
    signal switched(Item control, bool on)

    // The dashboard parts came after API v1's transitions, so effects may omit them.
    function optional(name) {
        return root.current && (name in root.current) && root.current[name] ? root.current[name] : null;
    }

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
