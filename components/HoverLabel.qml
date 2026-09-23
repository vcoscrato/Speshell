import QtQuick
import "../theme" as ThemeModule

// Name tag shown beside a rail item while the pointer is over it.
Rectangle {
    id: root

    property string text: ""

    anchors.left: parent.right
    anchors.leftMargin: ThemeModule.Theme.spacingTiny
    anchors.verticalCenter: parent.verticalCenter
    width: labelText.implicitWidth + ThemeModule.Theme.spacingLarge
    height: Math.max(26, labelText.implicitHeight + ThemeModule.Theme.spacingSmall)
    radius: ThemeModule.Theme.borderRadiusSmall
    color: ThemeModule.Theme.surface2
    border.width: ThemeModule.Theme.borderWidth
    border.color: ThemeModule.Theme.selectedBorder
    z: 100

    Text {
        id: labelText

        anchors.centerIn: parent
        text: root.text
        textFormat: Text.PlainText
        font.pixelSize: ThemeModule.Theme.fontSizeSmall
        font.family: ThemeModule.Theme.fontFamily
        color: ThemeModule.Theme.text
    }
}
