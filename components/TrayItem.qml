// qmllint disable missing-type unresolved-type
import QtQuick
import "../theme" as ThemeModule
import "." as Components

// One app's system tray icon: left click activates it, or opens its menu when it
// only has one; right click opens the menu at (menuX, menuY), or above the icon.
Item {
    id: root

    required property var modelData
    property real menuX: root.width + ThemeModule.Theme.spacingSmall
    property real menuY: 0
    property bool menuAbove: false
    property string labelPlacement: "right"
    readonly property bool menuOpen: menu.visible
    property bool pointerInside: false
    readonly property bool containingWindowVisible: !!(root.Window
        && root.Window.window
        && root.Window.window.visible)
    readonly property string labelText: root.modelData.tooltipTitle
        || root.modelData.title
        || root.modelData.id
        || "System tray icon"
    readonly property string iconPath: {
        var icon = root.modelData.icon;
        if (!icon)
            return "";
        var s = icon.toString();
        var pi = s.indexOf("?path=");
        return pi !== -1 ? s.substring(0, pi) : s;
    }

    function activate() {
        if (root.modelData.onlyMenu && root.modelData.hasMenu)
            menu.open();
        else
            root.modelData.activate();
    }

    width: ThemeModule.Theme.controlHeight
    height: ThemeModule.Theme.controlHeight

    Connections {
        target: root.Window ? root.Window.window : null

        function onVisibleChanged() {
            if (!root.containingWindowVisible)
                root.pointerInside = false;
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: root.labelText
    Accessible.onPressAction: root.activate()

    Rectangle {
        anchors.fill: parent
        color: root.pointerInside ? ThemeModule.Theme.cardHover : "transparent"
        radius: ThemeModule.Theme.borderRadiusSmall

        Image {
            id: trayImage
            anchors.centerIn: parent
            width: ThemeModule.Theme.iconSizeMedium
            height: ThemeModule.Theme.iconSizeMedium
            visible: root.iconPath !== ""
            source: root.iconPath
            sourceSize: Qt.size(ThemeModule.Theme.iconSizeMedium, ThemeModule.Theme.iconSizeMedium)
            fillMode: Image.PreserveAspectFit
        }

        Components.AppIcon {
            anchors.centerIn: parent
            name: "tray-fallback"
            size: ThemeModule.Theme.iconSizeMedium
            iconColor: ThemeModule.Theme.subtext
            visible: !trayImage.visible
        }
    }

    Components.HoverLabel {
        visible: root.containingWindowVisible
            && root.pointerInside
            && !root.menuOpen
            && root.labelText !== ""
        text: root.labelText
        placement: root.labelPlacement
    }

    Components.TrayMenu {
        id: menu
        handle: root.modelData.menu
        x: root.menuX
        y: root.menuAbove ? -menu.height - ThemeModule.Theme.spacingMedium : root.menuY
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: root.pointerInside = true
        onExited: root.pointerInside = false
        onCanceled: root.pointerInside = false
        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton)
                root.activate();
            else if (root.modelData.hasMenu)
                menu.open();
        }
    }
}
