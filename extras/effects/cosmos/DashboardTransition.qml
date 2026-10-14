import QtQuick
import "common"
import "common/Colors.js" as Colors

// Cosmos dashboard entrance: a star flares on the Speshell mark and the panel opens
// out of it through a lens-edged portal that sweeps to the far corner, top first.
Item {
    id: root

    // ── Speshell effects API v1: dashboard transition ──────
    property Item panel: null
    property rect panelRect
    property var theme: null
    signal finished()

    // ── Choreography (seconds) ──────────────────────────────
    readonly property real openTime: 0.3

    property real open: 0
    property bool done: false

    readonly property real eased: 1 - Math.pow(1 - open, 3)
    // The Speshell mark, at the top of the sidebar.
    readonly property point origin: Qt.point(panelRect.x + 30, panelRect.y + 26)
    readonly property real reach: Math.sqrt(Math.pow(panelRect.width, 2) + Math.pow(panelRect.height, 2)) + 20

    EffectClock {
        onAdvanced: function(dt) {
            // Finish a tick after the settled panel has drawn, so nothing jumps when
            // the entrance goes.
            if (root.open >= 1) {
                if (!root.done) {
                    root.done = true;
                    // Speshell may destroy this item inside the signal, so nothing may follow it.
                    root.finished();
                }
                return;
            }
            root.open = Math.min(1, root.open + dt / root.openTime);
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
        property rect rect: root.panelRect
        property point origin: root.origin
        // Open a little from the first frame, so the mark shows at once.
        property real circle: 36 + root.eased * (root.reach - 36)
        property real outside: 0
        property real lens: 14 * (1 - root.eased)
        property real ringWidth: 1
        property real ring: root.open < 1 ? 1 : 0
        property color cHot: root.theme ? Qt.lighter(Colors.mix(root.theme.text, root.theme.yellow, 0.15), 1.2) : "#fbf1c7"
        property color cGlow: root.theme ? root.theme.accent : "#fe8019"
        property color cHaze: root.theme ? root.theme.pink : "#d3869b"
        fragmentShader: Qt.resolvedUrl("shaders/portal.frag.qsb")
    }

    Glint {
        cx: root.origin.x
        cy: root.origin.y
        size: 150
        spin: 0.2 + root.open * 0.8
        cHot: root.theme ? Qt.lighter(Colors.mix(root.theme.text, root.theme.yellow, 0.15), 1.2) : "#fbf1c7"
        cGlow: root.theme ? root.theme.accent : "#fabd2f"
        k: root.open < 0.12 ? root.open / 0.12 : Math.max(0, 1 - (root.open - 0.12) / 0.4)
    }
}
