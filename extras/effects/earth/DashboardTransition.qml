import QtQuick
import "common"

// Earth dashboard entrance: the panel rises into place as blocks of stone, top
// first, each landing with a jolt and a puff of dust; the cracks between them close
// as the last ones settle.
Item {
    id: root

    // ── Speshell effects API v1: dashboard transition ──────
    property Item panel: null
    property rect panelRect
    property var theme: null
    signal finished()

    // ── Choreography (seconds) ──────────────────────────────
    readonly property real riseTime: 0.34

    // A little along from the first frame, so the top blocks show at once.
    property real rise: 0.05
    property bool done: false

    EffectClock {
        id: clock
        onAdvanced: function(dt) {
            // Finish a tick after the settled panel has drawn, so nothing jumps when
            // the entrance goes.
            if (root.rise >= 1) {
                if (!root.done) {
                    root.done = true;
                    // Speshell may destroy this item inside the signal, so nothing may follow it.
                    root.finished();
                }
                return;
            }
            root.rise = Math.min(1, root.rise + dt / root.riseTime);
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
        property real rise: root.rise
        property color cShade: root.theme ? root.theme.crust : "#0d0f0a"
        property color cDust: root.theme ? root.theme.peach : "#d99a5a"
        property color cJade: root.theme ? root.theme.accent : "#5fa57a"
        fragmentShader: Qt.resolvedUrl("shaders/rise.frag.qsb")
    }
}
