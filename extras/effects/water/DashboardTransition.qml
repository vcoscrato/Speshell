import QtQuick
import "common"

// Water dashboard entrance: a sheet of water slides down the panel from the top edge,
// tongues running ahead of its foam crest. The panel shows deep under it, bent and lit
// by caustics, then clear behind its waterline, which follows the front down and
// drains off the bottom edge, leaving drops running down the glass.
Item {
    id: root

    // ── Speshell effects API v1: dashboard transition ──────
    property Item panel: null
    property rect panelRect
    property var theme: null
    signal finished()

    // ── Choreography (seconds) ──────────────────────────────
    readonly property real washTime: 0.4

    property real wash: 0
    property bool done: false

    EffectClock {
        id: clock
        onAdvanced: function(dt) {
            // Finish a tick after the settled panel has drawn, so nothing jumps when
            // the entrance goes.
            if (root.wash >= 1) {
                if (!root.done) {
                    root.done = true;
                    // Speshell may destroy this item inside the signal, so nothing may follow it.
                    root.finished();
                }
                return;
            }
            root.wash = Math.min(1, root.wash + dt / root.washTime);
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
        // The front rushes in, over the top edge on the first frame, and slows toward
        // the bottom; the waterline sets off after it and speeds up to drain away.
        property real head: 0.06 + 0.94 * (1 - Math.pow(1 - Math.min(1, root.wash / 0.6), 2))
        property real tail: Math.pow(Math.max(0, (root.wash - 0.15) / 0.85), 1.5)
        property real time: clock.clock
        property color cLight: root.theme ? root.theme.sky : "#7fd3f0"
        property color cFoam: root.theme ? root.theme.text : "#e3eef4"
        property color cWater: root.theme ? root.theme.accent : "#4a97d8"
        fragmentShader: Qt.resolvedUrl("shaders/wash.frag.qsb")
    }
}
