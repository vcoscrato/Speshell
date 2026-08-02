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
    readonly property string effectiveTooltipText: root.tooltipText !== ""
        ? root.tooltipText
        : (root.statusText !== ""
            ? root.statusText
            : (WidgetRegistry.label(root.widgetName) || root.widgetName))
    readonly property color currentIconColor: root.active
        ? ThemeModule.Theme.accent
        : (mouseArea.containsMouse ? ThemeModule.Theme.text : ThemeModule.Theme.subtextBright)

    signal activated(string name)
    signal wheelDelta(int angleDelta)

    width: parent ? parent.width : ThemeModule.Theme.sidebarIconSize
    height: ThemeModule.Theme.sidebarIconSize
    color: "transparent"

    Rectangle {
        id: iconTile
        anchors.centerIn: parent
        width: 38
        height: 38
        radius: ThemeModule.Theme.borderRadiusSmall
        color: root.active
            ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.14)
            : (mouseArea.containsMouse ? ThemeModule.Theme.cardHover : "transparent")
        border.width: root.active ? ThemeModule.Theme.borderWidth : 0
        border.color: Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.32)

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
        visible: mouseArea.containsMouse && root.effectiveTooltipText !== ""
        text: root.effectiveTooltipText
        delay: 150
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated(root.widgetName)
        onWheel: function(wheel) {
            root.wheelDelta(wheel.angleDelta.y)
        }
    }

}
