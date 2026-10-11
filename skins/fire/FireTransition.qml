import QtQuick
import "common"

// Fire launcher transition: an ember flares, a burning edge sweeps the panel into
// view, and flames simmer around it while open. Closing burns a hole through the
// middle of the panel that spreads outward until it is gone.
Item {
    id: root

    // ── Speshell skin API v1 ────────────────────────────────
    property Item panel: null
    property rect panelRect
    property bool active: false
    signal closingFinished()

    // ── Choreography (seconds) ──────────────────────────────
    readonly property real igniteTime: 0.22
    readonly property real sweepTime: 0.8
    readonly property real burnTime: 0.55
    readonly property real tailTime: 0.35     // flames left burning after the panel is gone
    readonly property real simmer: 0.55       // rim flame strength while open

    readonly property color core: "#fff6c8"

    property real phaseStart: 0
    property bool sparkPending: true
    property bool exitDone: false

    // sweep: 0..1 progress of the entrance front; burn: 0..1 progress of the exit hole.
    property real sweep: 0
    property real burn: 0
    readonly property point revealOrigin: Qt.point(panelRect.x + panelRect.width * 0.22,
                                                   panelRect.y + panelRect.height * 0.82)
    readonly property point burnOrigin: Qt.point(panelRect.x + panelRect.width * 0.5,
                                                 panelRect.y + panelRect.height * 0.55)
    // Past these radii the ragged fronts have cleared every panel corner.
    readonly property real revealMax: Math.sqrt(Math.pow(panelRect.width * 0.78 * 0.85, 2)
                                                + Math.pow(panelRect.height * 0.82 * 1.15, 2)) + 90
    readonly property real burnMax: Math.sqrt(Math.pow(panelRect.width * 0.5 * 0.85, 2)
                                              + Math.pow(panelRect.height * 0.55 * 1.15, 2)) + 90
    readonly property real revealR: -30 + (1 - Math.pow(1 - sweep, 1.5)) * (revealMax + 30)
    // Slow to catch, then racing outward.
    readonly property real burnR: -20 + Math.pow(burn, 1.3) * (burnMax + 20)
    readonly property bool capturing: sweep < 1 || burn > 0
    readonly property real phaseAge: clock.clock - phaseStart

    onActiveChanged: {
        phaseStart = clock.clock;
        exitDone = false;
    }

    EffectClock {
        id: clock
        onAdvanced: function(dt) {
            if (root.active) {
                // Reopened mid-exit: the hole closes up again.
                if (root.burn > 0) {
                    root.burn = Math.max(0, root.burn - dt / root.burnTime);
                    return;
                }
                if (root.sparkPending && root.phaseAge < root.igniteTime)
                    return;
                root.sparkPending = false;
                root.sweep = Math.min(1, root.sweep + dt / root.sweepTime);
            } else if (root.burn < 1) {
                root.burn = Math.min(1, root.burn + dt / root.burnTime);
                root.phaseStart = clock.clock;
            } else if (!root.exitDone && root.phaseAge >= root.tailTime) {
                root.exitDone = true;
                // Speshell may destroy this item inside the signal, so nothing may follow it.
                root.closingFinished();
            }
        }
    }

    Flames {
        anchors.fill: parent
        readonly property bool exiting: root.burn > 0
        time: clock.simTime
        emit: root.active && !exiting ? root.simmer * Math.max(0, Math.min(1, (root.sweep - 0.5) / 0.5)) : 0
        frontFuel: (root.sweep > 0 && root.sweep < 1) || (root.burn > 0 && root.burn < 1) ? 1 : 0
        panelRect: root.panelRect
        origin: exiting ? root.burnOrigin : root.revealOrigin
        burnR: exiting ? root.burnR : root.revealR
        core: root.core
    }

    // ── The panel between the fronts; otherwise the real panel shows ──
    ShaderEffectSource {
        id: panelTex
        sourceItem: root.panel
        hideSource: root.capturing
        live: root.capturing
    }

    ShaderEffect {
        visible: root.capturing && root.panel !== null
        x: root.panelRect.x
        y: root.panelRect.y
        width: root.panelRect.width
        height: root.panelRect.height
        property var source: panelTex
        property rect rect: root.panelRect
        property point revealOrigin: root.revealOrigin
        property real revealR: root.revealR
        property point burnOrigin: root.burnOrigin
        property real burnR: root.burn > 0 ? root.burnR : -1e5
        property real fieldScale: 1
        property color cGlow: "#ff8a1f"
        property color cHot: root.core
        property color cChar: "#3a120c"
        fragmentShader: Qt.resolvedUrl("shaders/burn.frag.qsb")
    }

    // ── Ignition ember ──
    Rectangle {
        readonly property real k: Math.min(1, root.phaseAge / root.igniteTime)
        visible: root.active && root.sparkPending
        x: root.revealOrigin.x - width / 2
        y: root.revealOrigin.y - height / 2
        width: 6 + 26 * k
        height: width
        radius: width / 2
        color: root.core
        border.color: "#ff8a1f"
        border.width: 3
    }
}
