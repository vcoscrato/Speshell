import QtQuick
import "common"

// Water's effects on the dashboard's controls. A knob dragged down a slider pours
// water out: it drips and runs off the track it leaves empty. Dragged up, water pours
// in: drops fall onto the track it fills and splash there. Either way it ripples the
// track now and then; let go, it rings out in one more. Picking something sends
// ripples out from it and pops a few drops. A switch turned on bubbles; turned off, it
// ripples and drips.
Item {
    id: root

    // ── Speshell effects API v1: dashboard interactions ─────
    property var theme: null

    // Travel not yet paid out in drops and ripples, px.
    property real dropOwed: 0
    property real rippleOwed: 0
    property real rippleEvery: 30

    function rnd(a, b) {
        return a + Math.random() * (b - a);
    }

    function drop(x, y, vx, vy) {
        bits.spawn({ x: x, y: y, vx: vx, vy: vy, gravity: 900, life: rnd(0.4, 0.6), size: Math.round(rnd(7, 11)),
                     orient: true, props: { kind: 0, seed: Math.random(), arrive: 0, z: 2 } });
    }

    // A drop falling from the track, slow to let go.
    function drip(x, y, size, delay) {
        bits.spawn({ x: x, y: y, vx: rnd(-8, 8), vy: rnd(10, 60), gravity: 1100, life: rnd(0.45, 0.6), delay: delay,
                     size: size, orient: true, props: { kind: 0, seed: Math.random(), arrive: 0, z: 2 } });
    }

    // A drop poured in from above, landing on (tx, ty) after `t` seconds with a splash.
    function pour(tx, ty, t) {
        var g = 1400, x = tx + rnd(-4, 4), y = ty - rnd(46, 72);
        bits.spawn({ x: x, y: y, vx: (tx - x) / t, vy: (ty - y) / t - 0.5 * g * t, gravity: g, life: t,
                     size: Math.round(rnd(15, 20)), orient: true, props: { kind: 0, seed: Math.random(), arrive: 1, z: 2 } });
        bits.spawn({ x: tx, y: ty, life: 0.3, delay: t, size: Math.round(rnd(16, 22)),
                     props: { kind: 1, seed: Math.random(), squash: 0.35, z: 0 } });
        if (Math.random() < 0.5) {
            for (var i = 0; i < 2; i++)
                bits.spawn({ x: tx, y: ty - 2, vx: rnd(-80, 80), vy: -rnd(90, 150), gravity: 900, life: rnd(0.2, 0.3),
                             delay: t, size: 6, orient: true, props: { kind: 0, seed: Math.random(), arrive: 0, z: 2 } });
        }
    }

    function ripple(x, y, size, squash, delay) {
        bits.spawn({ x: x, y: y, life: 0.55, delay: delay || 0, size: size,
                     props: { kind: 1, seed: Math.random(), squash: squash, z: 0 } });
    }

    function bubble(x, y) {
        bits.spawn({ x: x, y: y, vx: rnd(-20, 20), vy: -rnd(40, 80), gravity: -120, life: rnd(0.5, 0.75),
                     size: Math.round(rnd(6, 11)), props: { kind: 2, seed: Math.random(), z: 1 } });
    }

    function slide(at, dx) {
        var back = dx > 0 ? -1 : 1;
        var every = dx < 0 ? 5 : 8;
        root.dropOwed = Math.min(root.dropOwed + Math.abs(dx), 48);
        while (root.dropOwed >= every) {
            root.dropOwed -= every;
            if (dx < 0) {
                // Down: the track just emptied pours off its underside.
                root.drip(at.x + root.dropOwed + rnd(2, 8), at.y + 4, Math.round(rnd(10, 15)), rnd(0, 0.05));
            } else {
                // Up: water pours onto the track just filled.
                root.pour(at.x - root.dropOwed - rnd(4, 22), at.y + 1, rnd(0.16, 0.22));
            }
        }
        root.rippleOwed += Math.abs(dx);
        if (root.rippleOwed >= root.rippleEvery) {
            root.rippleOwed = 0;
            root.rippleEvery = rnd(24, 48);
            root.ripple(at.x + back * rnd(0, 6), at.y + rnd(1, 4), Math.round(rnd(26, 44)), rnd(0.28, 0.42));
        }
    }

    function release(at) {
        root.ripple(at.x, at.y + 2, 48, 0.35);
        for (var i = 0; i < 3; i++)
            root.drop(at.x, at.y - 3, rnd(-80, 80), -rnd(160, 240));
    }

    function pick(area) {
        var cx = area.x + area.width / 2, cy = area.y + area.height / 2;
        var size = Math.max(40, Math.min(100, Math.max(area.width, area.height) * 2.2));
        root.ripple(cx, cy, size, 1);
        root.ripple(cx, cy, size * 0.8, 1, 0.12);
        for (var i = 0; i < 5; i++)
            root.drop(cx, cy, rnd(-110, 110), -rnd(170, 280));
    }

    function toggle(area, on) {
        var x = on ? area.x + area.width - area.height / 2 : area.x + area.height / 2;
        var cy = area.y + area.height / 2;
        if (on) {
            for (var i = 0; i < 4; i++)
                root.bubble(x + rnd(-6, 6), cy - rnd(0, 6));
            root.ripple(x, cy, 36, 1);
        } else {
            root.ripple(x, cy + area.height / 2, 40, 0.35);
            root.drop(x, cy + 4, rnd(-20, 20), 40);
        }
    }

    Particles {
        id: bits
        anchors.fill: parent
        capacity: 128
        delegate: Component {
            ShaderEffect {
                property real age: 0
                property real seed: 0
                property real kind: 0
                property real size: width
                property real arrive: 0
                property real squash: 1
                property color cWater: root.theme ? root.theme.accent : "#4a97d8"
                property color cLight: root.theme ? root.theme.sky : "#7fd3f0"
                property color cFoam: root.theme ? root.theme.text : "#e3eef4"
                property color cDeep: root.theme ? root.theme.crust : "#081016"
                fragmentShader: Qt.resolvedUrl("shaders/bits.frag.qsb")
            }
        }
    }
}
