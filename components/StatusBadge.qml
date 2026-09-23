import QtQuick
import "../theme" as ThemeModule

Rectangle {
    id: root

    property string text: ""
    property string tone: "neutral" // neutral | success | warning | error | info

    function toneColor() {
        return ThemeModule.Theme.toneColor(root.tone);
    }

    radius: height / 2
    implicitHeight: Math.max(18, badgeText.implicitHeight + ThemeModule.Theme.spacingTiny)
    height: implicitHeight
    width: badgeText.width + 14
    color: ThemeModule.Theme.alpha(root.toneColor(), ThemeModule.Theme.tintStrong)
    border.width: ThemeModule.Theme.borderWidth
    border.color: ThemeModule.Theme.alpha(root.toneColor(), ThemeModule.Theme.tintOutline)

    Text {
        id: badgeText
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: ThemeModule.Theme.fontSizeCaption
        font.family: ThemeModule.Theme.fontFamily
        font.bold: true
        color: root.toneColor()
    }
}
