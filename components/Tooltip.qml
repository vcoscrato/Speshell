import QtQuick
import QtQuick.Templates as T
import "../theme" as ThemeModule

// Hover text above a control, styled like HoverLabel. Declare it inside the control
// and drive `visible`.
T.ToolTip {
    id: root

    property real maxWidth: 260

    x: parent ? (parent.width - width) / 2 : 0
    y: -height - ThemeModule.Theme.spacingTiny
    width: Math.min(implicitWidth, root.maxWidth)
    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding
    margins: ThemeModule.Theme.spacingTiny
    horizontalPadding: ThemeModule.Theme.spacingSmall
    verticalPadding: ThemeModule.Theme.spacingTiny
    delay: 300
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent | T.Popup.CloseOnReleaseOutsideParent

    contentItem: Text {
        text: root.text
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        font.pixelSize: ThemeModule.Theme.fontSizeSmall
        font.family: ThemeModule.Theme.fontFamily
        color: ThemeModule.Theme.text
    }

    background: Rectangle {
        radius: ThemeModule.Theme.borderRadiusSmall
        color: ThemeModule.Theme.surface2
        border.width: ThemeModule.Theme.borderWidth
        border.color: ThemeModule.Theme.selectedBorder
    }
}
