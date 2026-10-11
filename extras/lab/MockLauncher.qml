import QtQuick
Rectangle {
    radius: 10; color: "#1d1416"; border.color: "#4a2a25"; border.width: 1
    Rectangle { x: 16; y: 16; width: parent.width - 32; height: 48; radius: 8; color: "#2b1d1f"
        Text { x: 44; anchors.verticalCenter: parent.verticalCenter; text: "Search apps and panels…"; color: "#9a8580"; font.pixelSize: 16 } }
    Column { x: 16; y: 80; spacing: 4
        Repeater { model: ["Firefox", "Terminal", "Files", "Settings"]
            Rectangle { required property string modelData; required property int index; width: 508; height: 52; radius: 8; color: index === 0 ? "#3a2622" : "transparent"
                Text { x: 50; anchors.verticalCenter: parent.verticalCenter; text: parent.modelData; color: "#eadbd5"; font.pixelSize: 14 } } } }
}
