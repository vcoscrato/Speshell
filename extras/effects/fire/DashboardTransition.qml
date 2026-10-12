import QtQuick
import "common"

// Fire dashboard entrance: the Speshell mark catches and a burning front spreads down
// the panel from it, flames licking off its edge, leaving the panel behind.
Item {
    id: root

    // ── Speshell effects API v1: dashboard transition ──────
    property Item panel: null
    property rect panelRect
    property var theme: null
    signal finished()

    // ── Choreography (seconds) ──────────────────────────────
    readonly property real sweepTime: 0.32
    readonly property real tailTime: 0.15     // the last flames dying once the panel is whole

    readonly property color core: "#fff6c8"

    property real sweep: 0
    property real tail: 0
    property bool done: false

    // Just above the Speshell mark, so the top of the panel burns in first.
    readonly property point revealOrigin: Qt.point(panelRect.x + 30, panelRect.y - 10)
    // Past this radius the ragged front has cleared the bottom corners.
    readonly property real revealMax: Math.sqrt(Math.pow((panelRect.width - 30) * 0.85, 2)
                                                + Math.pow((panelRect.height + 10) * 1.15, 2)) + 90
    // Lit a little from the first frame, so the mark shows at once.
    readonly property real revealR: 50 + (1 - Math.pow(1 - sweep, 1.6)) * (revealMax - 50)

    EffectClock {
        id: clock
        onAdvanced: function(dt) {
            if (root.sweep < 1) {
                root.sweep = Math.min(1, root.sweep + dt / root.sweepTime);
                return;
            }
            // Finish a tick after the settled panel has drawn, so nothing jumps when
            // the entrance goes.
            if (root.tail >= root.tailTime) {
                if (!root.done) {
                    root.done = true;
                    // Speshell may destroy this item inside the signal, so nothing may follow it.
                    root.finished();
                }
                return;
            }
            root.tail = Math.min(root.tailTime, root.tail + dt);
        }
    }

    // ── The panel inside the front ──
    ShaderEffectSource {
        id: panelTex
        sourceItem: root.panel
        hideSource: true
    }

    ShaderEffect {
        x: root.panelRect.x
        y: root.panelRect.y
        width: root.panelRect.width
        height: root.panelRect.height
        property var source: panelTex
        property rect rect: root.panelRect
        property point revealOrigin: root.revealOrigin
        property real revealR: root.revealR
        property point burnOrigin: root.revealOrigin
        property real burnR: -1e5
        property real refill: 0
        property real fade: 1
        property real fieldScale: 1
        property color cGlow: "#ff8a1f"
        property color cHot: root.core
        property color cChar: "#3a120c"
        fragmentShader: Qt.resolvedUrl("shaders/burn.frag.qsb")
    }

    Flames {
        anchors.fill: parent
        // Gone by the last frame, so the panel underneath is all that shows.
        opacity: 1 - root.tail / root.tailTime
        time: clock.simTime
        emit: 0
        frontFuel: root.sweep < 1 ? 1 : 0
        panelRect: root.panelRect
        origin: root.revealOrigin
        burnR: root.revealR
        core: root.core
    }
}
