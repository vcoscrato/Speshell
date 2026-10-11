import QtQuick

// A water whip along a log spiral. See shaders/whip.frag.
ShaderEffect {
    property real time: 0
    property size resolution: Qt.size(width, height)
    property point center
    property real r0: 600
    property real k: 0.35
    property real th0: 0
    property real spin: 1
    property real head: 0
    property real len: 3
    property real tubeWidth: 16
    property color cDeep: "#1d5f8c"
    property color cMid: "#2f8fc4"
    property color cLight: "#7cc9ea"
    property color cFoam: "#f2fbff"
    fragmentShader: Qt.resolvedUrl("shaders/whip.frag.qsb")
}
