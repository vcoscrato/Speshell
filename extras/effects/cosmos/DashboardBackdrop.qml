import QtQuick

// Cosmos dashboard backdrop: a faint nebula lane across the panel, star dust
// thickest along it, and a few glints. Drawn once.
ShaderEffect {
    id: root

    // ── Speshell effects API v1: dashboard backdrop ──────────
    property var theme: null

    property size size: Qt.size(width, height)
    property color cBase: root.theme ? root.theme.bg : "#282828"
    property color cDeep: root.theme ? root.theme.crust : "#1b1b1b"
    property color cText: root.theme ? root.theme.text : "#ebdbb2"
    property color cAccent: root.theme ? root.theme.accent : "#fe8019"
    fragmentShader: Qt.resolvedUrl("qsb/DashboardBackdrop.qsb")
}
