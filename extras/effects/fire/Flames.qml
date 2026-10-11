import QtQuick

// Cel-shaded flames from a quarter-resolution fluid simulation. Fuel comes from a
// simmering rim around `panelRect` and from the burn front at `burnR` around `origin`.
Item {
    id: root

    property real time: 0
    property real timeScale: 1     // the effect clock's speed; the simulation steps once per frame
    property real emit: 0          // 0..1 rim flames around panelRect
    property real frontFuel: 0     // 0..1 flames along the burn front
    property rect panelRect
    property real radius: 4
    property point origin
    property real burnR: -1
    property real fieldScale: 1
    property bool clearBehind: true   // keep flames off the panel once the front has passed

    property color core: "#fff6c8"
    property color mid: "#ffb02e"
    property color outer: "#f2541b"
    property color edge: "#a8160f"

    ShaderEffectSource {
        id: simState
        sourceItem: sim
        recursive: true
        live: true
        hideSource: true
        smooth: true
        format: ShaderEffectSource.RGBA16F
    }

    ShaderEffect {
        id: sim
        width: Math.max(1, Math.round(root.width / 4))
        height: Math.max(1, Math.round(root.height / 4))
        property var state: simState
        property real time: root.time
        property real dt: root.timeScale / 60
        property real emit: root.emit
        property real frontFuel: root.frontFuel
        property size resolution: Qt.size(root.width, root.height)
        property rect panel: root.panelRect
        property real radius: root.radius
        property point origin: root.origin
        property real burnR: root.burnR
        property real fieldScale: root.fieldScale
        property real clearBehind: root.clearBehind ? 1 : 0
        fragmentShader: Qt.resolvedUrl("shaders/flame_sim.frag.qsb")
    }

    ShaderEffect {
        anchors.fill: parent
        property var state: simState
        property real time: root.time
        property size resolution: Qt.size(width, height)
        property color cCore: root.core
        property color cMid: root.mid
        property color cOuter: root.outer
        property color cEdge: root.edge
        fragmentShader: Qt.resolvedUrl("shaders/flame_draw.frag.qsb")
    }
}
