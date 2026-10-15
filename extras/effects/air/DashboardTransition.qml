import QtQuick
import "common"

// Air dashboard entrance: a gust blows in from the screen edge and carries the panel
// in with it, streaks of wind racing ahead of a ragged front and leaves tumbling
// along the way.
Item {
    id: root

    // ── Speshell effects API v1: dashboard transition ──────
    property Item panel: null
    property rect panelRect
    property var theme: null
    signal finished()

    // ── Choreography (seconds) ──────────────────────────────
    readonly property real gustTime: 0.3
    readonly property real tailTime: 0.1      // the last streaks blowing out

    property real gust: 0
    property real tail: 0
    property bool done: false

    EffectClock {
        id: clock
        onAdvanced: function(dt) {
            if (root.gust < 1) {
                root.gust = Math.min(1, root.gust + dt / root.gustTime);
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
        // Quick to arrive, easing into place; already in at the edge on the first frame.
        property real front: 0.08 + 0.92 * (1 - Math.pow(1 - root.gust, 2.2))
        property real fade: 1 - root.tail / root.tailTime
        property real time: clock.clock
        property color cWind: root.theme ? root.theme.text : "#f4ead8"
        property color cLeaf: root.theme ? root.theme.accent : "#f39a3a"
        property color cLeafBack: root.theme ? root.theme.peach : "#f0a03c"
        property color cOutline: root.theme ? root.theme.crust : "#130f0b"
        fragmentShader: Qt.resolvedUrl("qsb/DashboardTransition.qsb")
    }
}
