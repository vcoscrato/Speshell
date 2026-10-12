import QtQuick
import "common"

// Air's effects on the dashboard's controls. A knob dragged along a slider sheds wisps
// of wind that stream off behind it, now and then lifting a leaf; let go, it curls
// into a little eddy. Picking something swirls a curl of wind around it with a leaf
// caught up. A switch turned on gusts; turned off, it lets a little dust settle.
Item {
    id: root

    // ── Speshell effects API v1: dashboard interactions ─────
    property var theme: null

    // Travel not yet paid out in wisps and leaves, px.
    property real wispOwed: 0
    property real leafOwed: 0
    property real leafEvery: 40
    property real gustOwed: 0

    function rnd(a, b) {
        return a + Math.random() * (b - a);
    }

    function wisp(x, y, vx, vy, size) {
        bits.spawn({ x: x, y: y, vx: vx, vy: vy, drag: 2.5, life: rnd(0.4, 0.6), size: size, orient: true,
                     props: { kind: 0, seed: Math.random(), z: 0 } });
    }

    function leaf(x, y, vx, vy) {
        bits.spawn({ x: x, y: y, vx: vx, vy: vy, gravity: 160, drag: 1.5, life: rnd(0.8, 1.0),
                     size: Math.round(rnd(12, 16)), angle: rnd(0, 360), spin: rnd(-420, 420),
                     props: { kind: 1, seed: Math.random(), z: 2 } });
    }

    function curl(x, y, size) {
        bits.spawn({ x: x, y: y, life: 0.55, size: size, props: { kind: 2, seed: Math.random(), z: 1 } });
    }

    function speck(x, y) {
        bits.spawn({ x: x, y: y, vx: rnd(-25, 25), vy: rnd(10, 40), drag: 1, life: rnd(0.5, 0.8), size: 4,
                     props: { kind: 3, seed: Math.random(), z: 1 } });
    }

    function slide(at, dx) {
        var back = dx > 0 ? -1 : 1;
        root.wispOwed = Math.min(root.wispOwed + Math.abs(dx), 40);
        while (root.wispOwed >= 9) {
            root.wispOwed -= 9;
            root.wisp(at.x + back * rnd(4, 12), at.y + rnd(-10, 10), back * rnd(60, 150), rnd(-30, 30),
                      Math.round(rnd(30, 52)));
        }
        // Now and then a long gust streaming off along the track.
        root.gustOwed += Math.abs(dx);
        if (root.gustOwed >= 34) {
            root.gustOwed = 0;
            root.wisp(at.x + back * 10, at.y + rnd(-3, 3), back * rnd(180, 260), rnd(-10, 10), Math.round(rnd(64, 84)));
        }
        root.leafOwed += Math.abs(dx);
        if (root.leafOwed >= root.leafEvery) {
            root.leafOwed = 0;
            root.leafEvery = rnd(30, 60);
            root.leaf(at.x + back * 6, at.y - 4, back * rnd(70, 160), -rnd(80, 170));
        }
    }

    function release(at) {
        root.curl(at.x, at.y, 46);
        root.speck(at.x - 4, at.y - 6);
        root.speck(at.x + 5, at.y - 3);
    }

    function pick(area) {
        var cx = area.x + area.width / 2, cy = area.y + area.height / 2;
        var size = Math.max(44, Math.min(96, Math.max(area.width, area.height) * 2));
        root.curl(cx, cy, size);
        root.leaf(cx + size * 0.3, cy - size * 0.2, rnd(40, 100), -rnd(80, 140));
        root.wisp(cx - size * 0.4, cy + size * 0.15, 30, -60, 34);
        root.wisp(cx + size * 0.4, cy - size * 0.15, -30, 60, 34);
    }

    function toggle(area, on) {
        var x = on ? area.x + area.width - area.height / 2 : area.x + area.height / 2;
        var cy = area.y + area.height / 2;
        if (on) {
            root.curl(x, cy, 36);
            root.leaf(x, cy - 6, rnd(40, 110), -rnd(90, 150));
        } else {
            for (var i = 0; i < 3; i++)
                root.speck(x + rnd(-6, 6), cy - rnd(0, 8));
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
                property color cWind: root.theme ? root.theme.text : "#f4ead8"
                property color cLeaf: root.theme ? root.theme.accent : "#f39a3a"
                property color cLeafBack: root.theme ? root.theme.peach : "#f0a03c"
                property color cOutline: root.theme ? root.theme.crust : "#130f0b"
                fragmentShader: Qt.resolvedUrl("shaders/bits.frag.qsb")
            }
        }
    }
}
