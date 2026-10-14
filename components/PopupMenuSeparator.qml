import QtQuick
import QtQuick.Templates as T
import "../theme" as ThemeModule

// A rule between groups of a PopupMenu.
T.MenuSeparator {
    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding
    horizontalPadding: ThemeModule.Theme.spacingSmall
    verticalPadding: ThemeModule.Theme.spacingTiny

    contentItem: Rectangle {
        implicitHeight: ThemeModule.Theme.separatorThickness
        color: ThemeModule.Theme.separator
    }
}
