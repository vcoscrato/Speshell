import QtQuick
import "../theme" as ThemeModule
import "../core/WidgetRegistry.js" as WidgetRegistry
import "." as Components

Rectangle {
    id: root

    property string widgetName: ""
    property string iconName: ""
    property bool active: false
    property string statusText: ""
    property string tooltipText: ""
    property bool pointerInside: false
    readonly property bool containingWindowVisible: !!(root.Window
        && root.Window.window
        && root.Window.window.visible)
    readonly property string effectiveTooltipText: root.tooltipText !== ""
        ? root.tooltipText
        : (root.statusText !== ""
            ? root.statusText
            : (WidgetRegistry.label(root.widgetName) || root.widgetName))
    readonly property color currentIconColor: root.active
        ? ThemeModule.Theme.accent
        : (root.pointerInside ? ThemeModule.Theme.text : ThemeModule.Theme.subtextBright)

    signal activated(string name)
    signal wheelDelta(int angleDelta)

    Connections {
        target: root.Window ? root.Window.window : null

        function onVisibleChanged() {
            if (!root.containingWindowVisible)
                root.pointerInside = false;
        }
    }

    width: parent ? parent.width : ThemeModule.Theme.sidebarIconSize
    height: ThemeModule.Theme.sidebarIconSize
    color: "transparent"

    Accessible.role: Accessible.Button
    Accessible.name: WidgetRegistry.label(root.widgetName) || root.widgetName
    Accessible.description: root.statusText
    Accessible.onPressAction: if (root.enabled) root.activated(root.widgetName)

    Rectangle {
        anchors.centerIn: parent
        width: 38
        height: 38
        radius: ThemeModule.Theme.borderRadiusSmall
        color: root.active
            ? ThemeModule.Theme.selectedFill
            : (root.pointerInside ? ThemeModule.Theme.cardHover : "transparent")
        border.width: root.active ? ThemeModule.Theme.borderWidth : 0
        border.color: ThemeModule.Theme.selectedBorder

        Components.AppIcon {
            name: root.iconName
            size: ThemeModule.Theme.iconSizeLarge
            iconColor: root.currentIconColor
            anchors.centerIn: parent
            visible: root.iconName !== ""
            opacity: root.enabled ? 1 : ThemeModule.Theme.disabledOpacity
        }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: -6
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 18
            radius: 0
            color: ThemeModule.Theme.accent
            visible: root.active
        }
    }

    Components.HoverLabel {
        visible: root.containingWindowVisible
            && root.pointerInside
            && root.effectiveTooltipText !== ""
        text: root.effectiveTooltipText
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.pointerInside = true
        onExited: root.pointerInside = false
        onCanceled: root.pointerInside = false
        onClicked: root.activated(root.widgetName)
        onWheel: function(wheel) {
            root.wheelDelta(wheel.angleDelta.y)
        }
    }

}
