import QtQuick

// Leaves and dust carried around a center by the wind. See shaders/debris.frag.
// Covers only the ring the debris can reach, centered on `center`.
ShaderEffect {
    readonly property real extent: r0 * 1.46 + 1.5 * turbulence + 1.6 * leafSize + 22
    x: center.x - extent
    y: center.y - extent
    width: 2 * extent
    height: 2 * extent
    property real time: 0
    property size resolution: Qt.size(width, height)
    property point origin: Qt.point(x, y)
    property point center
    property real leaves: 8
    property real dust: 14
    property real r0: 300
    property real spin: 1
    property real head: 0
    property real leafSize: 11
    property real turbulence: 12
    property rect mask
    property real maskRadius: 10
    property color cLeaf: "#f0a03c"
    property color cLeafBack: "#c9711f"
    property color cOutline: "#5a3417"
    property color cDust: "#e9f2fa"
    fragmentShader: Qt.resolvedUrl("shaders/debris.frag.qsb")
}
