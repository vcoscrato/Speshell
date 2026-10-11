import QtQuick

// Effect clock shared by every skin. Emits `advanced(dt)` about 60 times a second
// with the elapsed time, and steps `simTime` in fixed 1/60 s increments so
// simulations look the same on any display refresh rate.
//
// Inside the offscreen lab, an ancestor item with a `labTime` property drives the
// clock instead of the wall clock, so previews are frame-exact however slowly
// frames are captured.
Item {
    id: root

    readonly property real step: 1 / 60
    property real clock: 0
    property real simTime: 0
    property real acc: 0
    property real lastTime: -1

    // Emitted last in each tick, so a handler may cause this clock to be destroyed.
    signal advanced(real dt)

    readonly property Item labHost: {
        for (var item = root.parent; item; item = item.parent) {
            if (item.labTime !== undefined)
                return item;
        }
        return null;
    }

    function tick(now) {
        var dt = root.lastTime < 0 ? root.step : Math.min(0.1, now - root.lastTime);
        root.lastTime = now;
        if (dt <= 0)
            return;
        root.clock += dt;
        root.acc += dt;
        if (root.acc >= root.step - 1e-6) {
            root.acc = root.acc > 3 * root.step ? 0 : root.acc - root.step;
            root.simTime += root.step;
        }
        root.advanced(dt);
    }

    Timer {
        interval: 16
        repeat: true
        running: root.labHost === null
        onTriggered: root.tick(Date.now() / 1000)
    }

    Connections {
        target: root.labHost
        function onLabTimeChanged() { root.tick(root.labHost.labTime); }
    }
}
