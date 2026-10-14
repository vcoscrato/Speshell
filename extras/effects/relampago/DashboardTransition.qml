import QtQuick
import "common"
import "Bolt.js" as Bolt

// Relâmpago dashboard entrance: lightning forks down through the panel from the top,
// and the panel shows outward from the bolt behind a glowing front, top rows first.
// The bolt flashes twice and dies.
Item {
    id: root

    // ── Speshell effects API v1: dashboard transition ──────
    property Item panel: null
    property rect panelRect
    property var theme: null
    signal finished()

    // ── Choreography (seconds) ──────────────────────────────
    readonly property real strikeTime: 0.34

    // A little along from the first frame, so the top shows at once.
    property real progress: 0.04
    property bool done: false

    EffectClock {
        id: clock
        onAdvanced: function(dt) {
            // Finish a tick after the settled panel has drawn, so nothing jumps when
            // the entrance goes.
            if (root.progress >= 1) {
                if (!root.done) {
                    root.done = true;
                    // Speshell may destroy this item inside the signal, so nothing may follow it.
                    root.finished();
                }
                return;
            }
            root.progress = Math.min(1, root.progress + dt / root.strikeTime);
        }
    }

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
        property size size: Qt.size(width, height)
        property real progress: root.progress
        property real time: clock.clock
        property color cCore: Bolt.core(root.theme)
        property color cGlow: Bolt.glow(root.theme)
        property color cEdge: Bolt.edge(root.theme)
        fragmentShader: Qt.resolvedUrl("shaders/strike.frag.qsb")
    }
}
