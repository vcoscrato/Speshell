import QtQuick
import "common"

// Cosmos wallpaper transition: a star flares in the middle of the screen and goes
// supernova, its shock front sweeping the old wallpaper away to the new one.
Item {
    id: root

    // ── Speshell effects API v1 ────────────────────────────────
    property Item outgoing: null
    signal finished()

    // ── Choreography (seconds) ──────────────────────────────
    readonly property real flareTime: 0.3
    readonly property real sweepTime: 1.3

    readonly property color hot: "#fbf1c7"
    readonly property color warm: "#fe8019"
    readonly property color gold: "#fabd2f"
    readonly property color violet: "#d3869b"

    property real flare: 0
    property real sweep: 0
    property bool done: false
    readonly property point origin: Qt.point(width / 2, height / 2)
    readonly property real maxRadius: Math.sqrt(width * width + height * height) / 2 + 40
    // Bursting out, then slowing as it spreads.
    readonly property real eased: 1 - Math.pow(1 - sweep, 2.2)

    EffectClock {
        id: clock
        onAdvanced: function(dt) {
            if (root.flare < 1) {
                root.flare = Math.min(1, root.flare + dt / root.flareTime);
            } else if (root.sweep < 1) {
                root.sweep = Math.min(1, root.sweep + dt / root.sweepTime);
            } else if (!root.done) {
                root.done = true;
                // Speshell may destroy this item inside the signal, so nothing may follow it.
                root.finished();
            }
        }
    }

    ShaderEffectSource {
        id: outgoingTex
        sourceItem: root.outgoing
        hideSource: true
        live: false
    }

    ShaderEffect {
        anchors.fill: parent
        visible: root.sweep < 1
        property var source: outgoingTex
        property rect rect: Qt.rect(0, 0, width, height)
        property point origin: root.origin
        property real circle: root.eased * root.maxRadius
        property real outside: 1
        property real lens: 40 * (1 - root.sweep * 0.6)
        property real ringWidth: 3
        property real ring: root.sweep > 0 ? 1 - Math.pow(root.sweep, 4) : 0
        property color cHot: root.hot
        property color cGlow: root.warm
        property color cHaze: root.violet
        fragmentShader: Qt.resolvedUrl("shaders/portal.frag.qsb")
    }

    Glint {
        cx: root.origin.x
        cy: root.origin.y
        size: 520
        spin: 0.2 + root.eased * 0.6
        cHot: root.hot
        cGlow: root.gold
        k: root.sweep === 0 ? root.flare : Math.max(0, 1 - root.sweep * 1.6)
    }
}
