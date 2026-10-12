import QtQuick
import "common"

// Fire's effects on the dashboard's controls. A knob dragged along a slider sets the
// track alight behind it: a burning streak with flames standing on it that die down
// as it cools, throwing the odd spark; let go, it spits a few more. Picking something bursts a ring of flame around it. A switch turned on
// flares; turned off, it goes out in smoke.
Item {
    id: root

    // ── Speshell effects API v1: dashboard interactions ─────
    property var theme: null

    // Travel not yet paid out in streaks and flames, px.
    property real streakOwed: 0
    property real flameOwed: 0

    function rnd(a, b) {
        return a + Math.random() * (b - a);
    }

    function tongue(x, y, vx, size) {
        bits.spawn({ x: x, y: y, vx: vx, vy: -rnd(10, 70), gravity: -rnd(90, 220), drag: 2, life: rnd(0.3, 0.6),
                     size: size, props: { kind: 0, seed: Math.random(), z: 1 } });
    }

    function spark(x, y, vx, vy) {
        bits.spawn({ x: x, y: y, vx: vx, vy: vy, gravity: 380, life: rnd(0.35, 0.6), size: 12, orient: true,
                     props: { kind: 1, seed: Math.random(), z: 2 } });
    }

    function ring(x, y, size) {
        bits.spawn({ x: x, y: y, life: 0.45, size: size, props: { kind: 2, seed: Math.random(), z: 0 } });
    }

    // A flame standing where it was lit, its base on the track.
    function trailFlame(x, y, size) {
        bits.spawn({ x: x, y: y - size * 0.28, life: rnd(0.4, 0.7), size: size,
                     props: { kind: 0, seed: Math.random(), z: 1 } });
    }

    function streak(x, y) {
        bits.spawn({ x: x, y: y, life: rnd(0.55, 0.7), size: 18, props: { kind: 4, seed: Math.random(), z: 0 } });
    }

    function smoke(x, y, vx) {
        bits.spawn({ x: x, y: y, vx: vx, vy: -rnd(30, 50), drag: 2, life: rnd(0.6, 0.8), size: 20,
                     props: { kind: 3, seed: Math.random(), z: 0 } });
    }

    function slide(at, dx) {
        var back = dx > 0 ? -1 : 1;
        root.streakOwed = Math.min(root.streakOwed + Math.abs(dx), 48);
        while (root.streakOwed >= 8) {
            root.streakOwed -= 8;
            root.streak(at.x + back * (root.streakOwed + 4), at.y);
        }
        root.flameOwed = Math.min(root.flameOwed + Math.abs(dx), 48);
        while (root.flameOwed >= 9) {
            root.flameOwed -= 9;
            root.trailFlame(at.x + back * (root.flameOwed + rnd(4, 9)), at.y, Math.round(rnd(13, 24)));
            if (Math.random() < 0.2)
                root.spark(at.x + back * 6, at.y - 4, back * rnd(30, 110) + rnd(-30, 30), -rnd(140, 280));
        }
    }

    function release(at) {
        for (var i = 0; i < 5; i++)
            root.spark(at.x, at.y - 3, rnd(-110, 110), -rnd(170, 320));
        root.tongue(at.x, at.y - 3, 0, 22);
    }

    function pick(area) {
        var cx = area.x + area.width / 2, cy = area.y + area.height / 2;
        root.ring(cx, cy, Math.max(36, Math.min(90, Math.max(area.width, area.height) * 1.7)));
        for (var i = 0; i < 6; i++)
            root.spark(cx + rnd(-area.width, area.width) * 0.3, cy, rnd(-130, 130), -rnd(160, 300));
    }

    function toggle(area, on) {
        var x = on ? area.x + area.width - area.height / 2 : area.x + area.height / 2;
        var cy = area.y + area.height / 2;
        if (on) {
            root.ring(x, cy, 40);
            for (var i = 0; i < 4; i++)
                root.spark(x, cy - 3, rnd(-90, 120), -rnd(160, 280));
        } else {
            root.smoke(x - 4, cy - 6, -15);
            root.smoke(x + 4, cy - 10, 15);
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
                property color cCore: "#fff6c8"
                property color cMid: "#ffb02e"
                property color cOuter: "#f2541b"
                property color cEdge: "#a8160f"
                property color cSmoke: root.theme ? root.theme.overlay : "#8a5048"
                fragmentShader: Qt.resolvedUrl("shaders/bits.frag.qsb")
            }
        }
    }
}
