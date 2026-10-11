import QtQuick

// A ring of spiralling wind strokes over faint vortex mist. See shaders/gust.frag.
ShaderEffect {
    property real time: 0
    property size resolution: Qt.size(width, height)
    property point origin: Qt.point(x, y)
    property point center
    property real count: 4
    property real phase: 0
    property real r0: 600
    property real k: 0.13
    property real spin: 1
    property real head: 0
    property real len: 3
    property real strokeWidth: 7
    property real strokeAlpha: 1
    property real cycle: 0
    property real mist: 0
    property real mistRadius: 300
    property rect mask
    property real maskRadius: 10
    property color cBody: "#f6f9fc"
    property color cRim: "#7fa6c8"
    fragmentShader: Qt.resolvedUrl("shaders/gust.frag.qsb")
}
