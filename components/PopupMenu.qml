import QtQuick
import QtQuick.Templates as T
import "../theme" as ThemeModule
import "." as Components

// A dropdown or context menu of PopupMenuItem and PopupMenuSeparator. Submenus added
// with insertMenu cascade beside it.
T.Menu {
    id: root

    // As wide as its widest row; menus don't size to their rows on their own.
    implicitWidth: {
        var widest = implicitBackgroundWidth - leftPadding - rightPadding;
        for (var i = 0; i < root.count; i++)
            widest = Math.max(widest, root.itemAt(i).implicitWidth);
        return widest + leftPadding + rightPadding;
    }
    implicitHeight: implicitContentHeight + topPadding + bottomPadding
    margins: ThemeModule.Theme.spacingSmall
    padding: ThemeModule.Theme.spacingTiny
    overlap: ThemeModule.Theme.spacingTiny

    delegate: Components.PopupMenuItem {}

    contentItem: ListView {
        implicitHeight: contentHeight
        model: root.contentModel
        interactive: contentHeight > height
        clip: true
        currentIndex: root.currentIndex

        T.ScrollBar.vertical: Components.StyledScrollBar {}
    }

    background: Rectangle {
        implicitWidth: 160
        radius: ThemeModule.Theme.borderRadius
        color: ThemeModule.Theme.card
        border.width: ThemeModule.Theme.borderWidth
        border.color: ThemeModule.Theme.surface2
    }

    T.Overlay.modal: Item {}
    T.Overlay.modeless: Item {}
}
