import QtQuick
import "../theme" as ThemeModule

Rectangle {
    id: root

    property string text: ""
    property string tone: "neutral" // neutral | success | warning | error | info

    function toneColor() {
        return ThemeModule.Theme.toneColor(root.tone);
    }

    radius: 9
    height: 18
    width: badgeText.width + 14
    color: Qt.rgba(toneColor().r, toneColor().g, toneColor().b, 0.18)
    border.width: ThemeModule.Theme.borderWidth
    border.color: Qt.rgba(toneColor().r, toneColor().g, toneColor().b, 0.45)

    Text {
        id: badgeText
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: 10
        font.family: ThemeModule.Theme.fontFamily
        font.bold: true
        color: root.toneColor()
    }
}
