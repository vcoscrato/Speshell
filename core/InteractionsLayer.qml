import QtQuick
import "../services" as Services
import "../theme" as ThemeModule

// The theme effects' interactions over `host`: small effects where the user drags a
// slider, flips a switch, or picks something inside it. Fill the host and stack it
// above the host's content; it takes no input.
Loader {
    id: root

    required property Item host
    property bool presented: false

    // EffectClock runs at this speed and frame rate.
    property real timeScale: Services.EffectsService.dashboardSpeed
    property int frameRate: Services.EffectsService.frameRate

    // Untyped, so the effects' functions can be called on it.
    readonly property var interactions: root.item

    enabled: false
    active: root.presented && Services.EffectsService.dashboardInteractions !== null
    sourceComponent: Services.EffectsService.dashboardInteractions

    Binding {
        target: root.item
        property: "theme"
        value: ThemeModule.Theme
    }

    // Whether `item` is part of the host; popups and other windows are not.
    function holds(item) {
        for (var parentItem = item; parentItem; parentItem = parentItem.parent) {
            if (parentItem === root.host)
                return true;
        }
        return false;
    }

    function areaOf(item) {
        return item.mapToItem(root, 0, 0, item.width, item.height);
    }

    Connections {
        target: Services.EffectsService
        enabled: root.status === Loader.Ready

        function onKnobMoved(knob, dx) {
            if (root.holds(knob))
                root.interactions.slide(knob.mapToItem(root, knob.width / 2, knob.height / 2), dx);
        }

        function onKnobReleased(knob) {
            if (root.holds(knob))
                root.interactions.release(knob.mapToItem(root, knob.width / 2, knob.height / 2));
        }

        function onPicked(target) {
            if (root.holds(target))
                root.interactions.pick(root.areaOf(target));
        }

        function onSwitched(control, on) {
            if (root.holds(control))
                root.interactions.toggle(root.areaOf(control), on);
        }
    }
}
