import QtQuick
import QtQuick.Shapes

// A stand-in for Speshell's dashboard in `theme`'s colors, filled the way core/Dashboard.qml
// fills it: the base color with the effects' backdrop over it, rendered once into the
// cut-corner panel shape.
Item {
    id: root

    property var theme: null
    property Component backdrop: null
    readonly property int cut: 16
    readonly property int rail: 60

    Item {
        id: material
        width: root.width
        height: root.height
        visible: backdropLoader.status === Loader.Ready

        Rectangle { anchors.fill: parent; color: root.theme.bg }

        Loader {
            id: backdropLoader
            anchors.fill: parent
            sourceComponent: root.backdrop
        }

        Binding { target: backdropLoader.item; property: "theme"; value: root.theme }
    }

    ShaderEffectSource {
        id: materialTexture
        visible: false
        sourceItem: material.visible ? material : null
        hideSource: true
    }

    Shape {
        anchors.fill: parent
        antialiasing: true
        ShapePath {
            strokeWidth: 2
            strokeColor: Qt.tint(root.theme.surface2, Qt.rgba(root.theme.overlay.r, root.theme.overlay.g, root.theme.overlay.b, 0.12))
            fillColor: root.theme.bg
            fillItem: material.visible ? materialTexture : null
            startX: 0; startY: 0
            PathLine { x: root.width - root.cut; y: 0 }
            PathLine { x: root.width; y: root.cut }
            PathLine { x: root.width; y: root.height - root.cut }
            PathLine { x: root.width - root.cut; y: root.height }
            PathLine { x: 0; y: root.height }
            PathLine { x: 0; y: 0 }
        }
    }

    Rectangle { x: 1; y: 1; width: root.rail - 1; height: root.height - 2; color: root.theme.mantle }
    Rectangle { x: root.rail; width: 1; height: root.height; color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.72) }
    Rectangle {
        anchors.right: parent.right
        y: 40; width: 2; height: root.height - 80
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.1; color: root.theme.accent }
            GradientStop { position: 0.88; color: root.theme.accent }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    // Sidebar icons.
    Column {
        x: 11; y: 8; spacing: 22
        Repeater {
            model: 8
            Rectangle {
                required property int index
                width: 38; height: 38; radius: 3
                color: index === 0 ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.12) : "transparent"
                border.width: index === 0 ? 1 : 0
                border.color: Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.45)
                Rectangle { anchors.centerIn: parent; width: 18; height: 18; radius: 4; color: "transparent"; border.width: 2; border.color: index === 0 ? root.theme.accent : root.theme.subtext }
            }
        }
    }

    Item {
        x: root.rail + 13; y: 12
        width: root.width - root.rail - 26
        height: root.height - 24

        Column {
            width: parent.width
            spacing: 4
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "18:30"; color: root.theme.text; font.family: "Inter"; font.pixelSize: 40; font.weight: Font.DemiBold }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Saturday, August 1"; color: root.theme.subtextBright; font.family: "Inter"; font.pixelSize: 13 }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Good evening"; color: root.theme.subtext; font.family: "Inter"; font.pixelSize: 11 }
            Item { width: 1; height: 24 }

            Text { text: "WORKSPACES"; color: root.theme.subtext; font.family: "Inter"; font.pixelSize: 11; font.letterSpacing: 0.8 }
            Row {
                spacing: 6
                Repeater {
                    model: [3, 1, 2, 0, 1]
                    Rectangle {
                        required property int modelData
                        required property int index
                        width: 64; height: 44; radius: 4
                        color: Qt.rgba(root.theme.overlay.r, root.theme.overlay.g, root.theme.overlay.b, 0.12)
                        border.width: 1
                        border.color: index === 0 ? Qt.rgba(root.theme.accent.r, root.theme.accent.g, root.theme.accent.b, 0.85) : Qt.rgba(root.theme.overlay.r, root.theme.overlay.g, root.theme.overlay.b, 0.24)
                        Text { x: 6; y: 3; text: parent.index + 1; color: root.theme.subtext; font.family: "Inter"; font.pixelSize: 10 }
                        Row {
                            x: 6; y: 20; spacing: 3
                            Repeater { model: parent.parent.modelData; Rectangle { width: 16; height: 16; radius: 4; color: [root.theme.accent, root.theme.sky, root.theme.success][index % 3]; required property int index } }
                        }
                    }
                }
            }
            Item { width: 1; height: 24 }

            Row {
                spacing: 10
                Rectangle { width: 16; height: 16; radius: 3; color: "transparent"; border.width: 2; border.color: root.theme.subtext; anchors.verticalCenter: parent.verticalCenter }
                Item {
                    width: 240; height: 20
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: root.theme.card }
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.6; height: 4; radius: 2; color: root.theme.accent }
                    Rectangle { x: parent.width * 0.6 - 8; anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; radius: 8; color: root.theme.accent }
                }
                Text { text: "60%"; color: root.theme.subtext; font.family: "Inter"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
            }
            Repeater {
                model: ["Speakers", "Headphones"]
                Row {
                    required property string modelData
                    required property int index
                    spacing: 10; topPadding: 12
                    Rectangle { width: 12; height: 12; radius: 6; color: index === 0 ? root.theme.accent : "transparent"; border.width: 2; border.color: root.theme.accent }
                    Text { text: parent.modelData; color: root.theme.text; font.family: "Inter"; font.pixelSize: 12 }
                }
            }
            Item { width: 1; height: 24 }
            Text { text: "NOW PLAYING"; color: root.theme.subtext; font.family: "Inter"; font.pixelSize: 11; font.letterSpacing: 0.8 }
            Row {
                spacing: 12
                Rectangle { width: 56; height: 56; radius: 4; color: root.theme.card }
                Column {
                    spacing: 4; anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Gymnopédie No. 1"; color: root.theme.text; font.family: "Inter"; font.pixelSize: 13 }
                    Text { text: "Erik Satie"; color: root.theme.subtext; font.family: "Inter"; font.pixelSize: 11 }
                }
            }
        }

        Column {
            anchors.bottom: parent.bottom
            width: parent.width
            spacing: 14
            Text { text: "NOTIFICATIONS"; color: root.theme.subtext; font.family: "Inter"; font.pixelSize: 11; font.letterSpacing: 0.8 }
            Text { text: "No notifications"; color: root.theme.subtext; font.family: "Inter"; font.pixelSize: 11 }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.theme.surface2.r, root.theme.surface2.g, root.theme.surface2.b, 0.72) }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "August 2026"; color: root.theme.text; font.family: "Inter"; font.pixelSize: 13 }
            Grid {
                columns: 7; columnSpacing: 0; rowSpacing: 10
                Repeater {
                    model: 42
                    Item {
                        required property int index
                        readonly property int day: index - 5
                        width: (root.width - root.rail - 26) / 7; height: 22
                        Rectangle { anchors.centerIn: parent; width: 26; height: 26; radius: 13; color: root.theme.accent; visible: parent.day === 1 }
                        Text { anchors.centerIn: parent; visible: parent.day >= 1 && parent.day <= 31; text: parent.day; color: parent.day === 1 ? root.theme.bg : root.theme.text; font.family: "Inter"; font.pixelSize: 11 }
                    }
                }
            }
        }
    }
}
