import QtQuick
import QtQuick.Controls
import "../theme" as ThemeModule
import "../core/WidgetRegistry.js" as WidgetRegistry
import "." as Components

Rectangle {
    id: root

    property string widgetName: ""
    property string iconName: ""
    property bool active: false
    property string statusText: ""
    property string microStatus: ""
    property string tooltipText: ""
    property bool focusTooltipSuppressed: false
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

    onActiveFocusChanged: {
        if (!root.activeFocus)
            root.focusTooltipSuppressed = false;
    }

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
    activeFocusOnTab: root.enabled

    Accessible.role: Accessible.Button
    Accessible.name: WidgetRegistry.label(root.widgetName) || root.widgetName
    Accessible.description: root.statusText
    Accessible.onPressAction: if (root.enabled) root.activated(root.widgetName)

    Keys.onPressed: function(event) {
        if (!root.enabled || event.isAutoRepeat)
            return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.activated(root.widgetName);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Right) {
            root.wheelDelta(120);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Left) {
            root.wheelDelta(-120);
            event.accepted = true;
        }
    }

    Rectangle {
        id: iconTile
        anchors.centerIn: parent
        width: 38
        height: 38
        radius: ThemeModule.Theme.borderRadiusSmall
        color: root.active
            ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.14)
            : (root.pointerInside ? ThemeModule.Theme.cardHover : "transparent")
        border.width: root.activeFocus ? 2 : (root.active ? ThemeModule.Theme.borderWidth : 0)
        border.color: root.activeFocus
            ? ThemeModule.Theme.accent
            : Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.32)

        Components.AppIcon {
            name: root.iconName
            size: 23
            iconColor: root.currentIconColor
            anchors.centerIn: parent
            visible: root.iconName !== ""
            opacity: root.enabled ? 1 : 0.4
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

    ToolTip {
        visible: root.containingWindowVisible
            && (root.pointerInside
            || (root.activeFocus && !root.focusTooltipSuppressed))
            && root.effectiveTooltipText !== ""
        text: root.effectiveTooltipText
        delay: 150
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.pointerInside = true
        onExited: root.pointerInside = false
        onCanceled: root.pointerInside = false
        onClicked: {
            root.focusTooltipSuppressed = true;
            root.forceActiveFocus();
            root.activated(root.widgetName);
        }
        onWheel: function(wheel) {
            root.wheelDelta(wheel.angleDelta.y)
        }
    }

}
