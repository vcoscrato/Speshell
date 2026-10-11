import QtQuick
import "common"

// Air launcher transition: gusts spiral in and wrap the launcher, which unwinds out
// of the vortex into place. A breeze keeps circling it while open. Closing winds the
// panel back into the vortex as the gusts fly off outward.
Item {
    id: root

    // ── Speshell effects API v1 ────────────────────────────────
    property Item panel: null
    property rect panelRect
    property bool active: false
    signal closingFinished()

    // ── Choreography (seconds) ──────────────────────────────
    readonly property real enterTime: 0.95
    readonly property real exitTime: 0.5
    readonly property real tailTime: 0.12

    // enter: 0..1 entrance progress; leave: 0..1 exit progress.
    property real enter: 0
    property real leave: 0
    property real tailStart: 0
    property bool exitDone: false

    readonly property point center: Qt.point(panelRect.x + panelRect.width / 2, panelRect.y + panelRect.height / 2)
    readonly property real reach: Math.sqrt(panelRect.width * panelRect.width + panelRect.height * panelRect.height) / 2
    readonly property real spin: 1
    readonly property bool capturing: enter < 1 || leave > 0

    function ease(x) { return 1 - Math.pow(1 - Math.max(0, Math.min(1, x)), 3); }
    function span(x, a, b) { return Math.max(0, Math.min(1, (x - a) / (b - a))); }

    // The panel is wound up while the gusts arrive, and unwinds as they wrap it.
    readonly property real wind: Math.max(1 - ease(span(enter, 0.3, 1)), ease(span(leave, 0, 0.8)))

    onActiveChanged: exitDone = false

    EffectClock {
        id: clock
        onAdvanced: function(dt) {
            if (root.active) {
                // Reopened mid-exit: the panel unwinds back out first.
                if (root.leave > 0) {
                    root.leave = Math.max(0, root.leave - dt / root.exitTime);
                    return;
                }
                root.enter = Math.min(1, root.enter + dt / root.enterTime);
            } else if (root.leave < 1) {
                root.leave = Math.min(1, root.leave + dt / root.exitTime);
                root.tailStart = clock.clock;
            } else if (!root.exitDone && clock.clock - root.tailStart >= root.tailTime) {
                root.exitDone = true;
                // Speshell may destroy this item inside the signal, so nothing may follow it.
                root.closingFinished();
            }
        }
    }

    // ── Arriving gusts: spiral in from far out and wrap the panel ──
    Gust {
        readonly property real startR: root.reach * 2.8
        readonly property real k0: 0.14
        anchors.fill: parent
        visible: root.enter < 1 && root.leave === 0
        time: clock.simTime
        center: root.center
        count: 3
        phase: -0.6
        r0: startR
        k: k0
        spin: root.spin
        len: 2.2
        head: root.ease(root.span(root.enter, 0, 0.8)) * (Math.log(startR / (root.reach * 1.05)) / k0 + 1.2)
        strokeWidth: 7
        strokeAlpha: 1 - root.span(root.enter, 0.72, 1)
        mist: Math.min(root.span(root.enter, 0, 0.35), 1 - root.span(root.enter, 0.6, 1))
        mistRadius: root.reach * 1.25
    }

    // ── Breeze while open: strokes circling the launcher on staggered cycles ──
    Gust {
        readonly property real size: root.reach * 1.5
        x: root.center.x - size
        y: root.center.y - size
        width: 2 * size
        height: 2 * size
        opacity: root.span(root.enter, 0.8, 1) * (1 - root.span(root.leave, 0, 0.3))
        visible: opacity > 0
        time: clock.simTime
        center: root.center
        count: 3
        phase: clock.simTime * 0.12
        r0: root.reach * 1.16
        k: 0.045
        spin: root.spin
        len: 1.7
        head: 7
        cycle: 4.5
        strokeWidth: 4.5
        strokeAlpha: 0.9
        mist: 0.5
        mistRadius: root.reach * 1.05
        mask: root.panelRect
    }

    // ── Departing gusts: burst outward from the panel ──
    Gust {
        anchors.fill: parent
        visible: root.leave > 0
        time: clock.simTime
        center: root.center
        count: 4
        phase: 0.4
        r0: root.reach * 0.75
        k: -0.16
        spin: root.spin
        len: 2.6
        head: root.ease(root.leave) * 8.5
        strokeWidth: 6
        strokeAlpha: 1 - root.span(root.leave, 0.65, 1)
        mist: 0.6 * Math.sin(Math.PI * root.leave)
        mistRadius: root.reach * (1 + root.leave)
    }

    // ── The panel, wound into the vortex; otherwise the real panel shows ──
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
        property point center: root.center
        property real wind: root.wind
        property real spin: root.spin
        property real reach: root.reach
        property color cRing: "#eef5fb"
        fragmentShader: Qt.resolvedUrl("shaders/unwind.frag.qsb")
    }
}
