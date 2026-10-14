import QtQuick
import "../theme" as ThemeModule

// Name tag shown beside a rail item, or below or above a bar item, while the pointer is
// over it.
Rectangle {
    id: root

    property string text: ""
    // "right" of the item, "below" or "above" it centered, or "below-end" or "above-end",
    // flush with its right edge for items near the screen's right edge.
    property string placement: "right"
    readonly property bool centered: root.placement === "below" || root.placement === "above"

    x: root.placement === "right"
        ? parent.width + ThemeModule.Theme.spacingTiny
        : (root.centered ? (parent.width - root.width) / 2 : parent.width - root.width)
    y: root.placement === "right"
        ? (parent.height - root.height) / 2
        : (root.placement.indexOf("below") === 0
            ? parent.height + ThemeModule.Theme.spacingSmall
            : -root.height - ThemeModule.Theme.spacingSmall)
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
