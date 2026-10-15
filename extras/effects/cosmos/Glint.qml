import QtQuick

// A star glint centered on (cx, cy).
ShaderEffect {
    id: root
    property real cx: 0
    property real cy: 0
    property real size: 160
    property real k: 0
    property real spin: 0.2
    property color cHot: "#fbf1c7"
    property color cGlow: "#fabd2f"

    visible: k > 0.001
    x: cx - size / 2
    y: cy - size / 2
    width: size
    height: size
    fragmentShader: Qt.resolvedUrl("qsb/Glint.qsb")
}
