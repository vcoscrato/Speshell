import QtQuick
import "common"
import "common/Colors.js" as Colors

// Cosmos's effects on the dashboard's controls. A knob dragged along a slider leaves a
// trail of star dust that twinkles out, with now and then a glint; let go, a star
// flares where it stops. Picking something sets off a small nova around it, scattering
// dust. A switch turned on flares; turned off, a little dust drifts off it.
Item {
    id: root

    // ── Speshell effects API v1: dashboard interactions ─────
    property var theme: null

    // Travel not yet paid out in dust and glints, px.
    property real dustOwed: 0
    property real glintOwed: 0
    property real glintEvery: 60

    function rnd(a, b) {
        return a + Math.random() * (b - a);
    }

    function mote(x, y, vx, vy) {
        bits.spawn({ x: x, y: y, vx: vx, vy: vy, drag: 2, life: rnd(0.5, 0.9), size: Math.round(rnd(4, 7)),
                     props: { kind: 0, seed: Math.random(), z: 1 } });
    }

    function glint(x, y, size) {
        bits.spawn({ x: x, y: y, life: 0.4, size: size, props: { kind: 1, seed: Math.random(), z: 2 } });
    }

    function nova(x, y, size) {
        bits.spawn({ x: x, y: y, life: 0.5, size: size, props: { kind: 2, seed: Math.random(), z: 0 } });
    }

    function burst(x, y, count, speed) {
        for (var i = 0; i < count; i++) {
            var a = (i + Math.random() * 0.8) / count * 2 * Math.PI;
            var v = rnd(0.5, 1) * speed;
            root.mote(x, y, Math.cos(a) * v, Math.sin(a) * v);
        }
    }

    function slide(at, dx) {
        var back = dx > 0 ? -1 : 1;
        root.dustOwed = Math.min(root.dustOwed + Math.abs(dx), 30);
        while (root.dustOwed >= 5) {
            root.dustOwed -= 5;
            root.mote(at.x + back * rnd(2, 8), at.y + rnd(-7, 7), back * rnd(5, 35), rnd(-20, 20));
        }
        root.glintOwed += Math.abs(dx);
        if (root.glintOwed >= root.glintEvery) {
            root.glintOwed = 0;
            root.glintEvery = rnd(40, 90);
            root.glint(at.x + back * rnd(6, 14), at.y + rnd(-8, 8), Math.round(rnd(14, 20)));
        }
    }

    function release(at) {
        root.glint(at.x, at.y, 28);
        root.burst(at.x, at.y, 4, 70);
    }

    function pick(area) {
        var cx = area.x + area.width / 2, cy = area.y + area.height / 2;
        var size = Math.max(40, Math.min(96, Math.max(area.width, area.height) * 2));
        root.nova(cx, cy, size);
        root.glint(cx, cy, Math.round(size * 0.6));
        root.burst(cx, cy, 7, size * 2);
    }

    function toggle(area, on) {
        var x = on ? area.x + area.width - area.height / 2 : area.x + area.height / 2;
        var cy = area.y + area.height / 2;
        if (on) {
            root.glint(x, cy, 26);
            root.burst(x, cy, 4, 80);
        } else {
            root.mote(x - 2, cy - 4, -15, -25);
            root.mote(x + 2, cy - 2, 15, -20);
        }
    }

    Particles {
        id: bits
        anchors.fill: parent
        delegate: Component {
            ShaderEffect {
                property real age: 0
                property real seed: 0
                property real kind: 0
                property real size: width
                property color cStar: root.theme ? root.theme.text : "#ebdbb2"
                property color cHot: root.theme ? Qt.lighter(Colors.mix(root.theme.text, root.theme.yellow, 0.15), 1.2) : "#fbf1c7"
                property color cGlow: root.theme ? root.theme.accent : "#fe8019"
                property color cHaze: root.theme ? root.theme.pink : "#d3869b"
                fragmentShader: Qt.resolvedUrl("shaders/bits.frag.qsb")
            }
        }
    }
}
