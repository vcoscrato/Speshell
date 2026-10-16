pragma ComponentBehavior: Bound
import QtQuick
import "../services" as Services
import "../theme" as ThemeModule
import "../core/WidgetRegistry.js" as WidgetRegistry
import "." as Components

Rectangle {
    id: root

    property string widgetName: ""
    property string iconName: ""
    property bool active: false
    property string statusText: ""
    // A secondary icon splits the button: both halves open the panel, and the
    // wheel and right click report which half they came over.
    property string secondaryIconName: ""
    property string secondaryStatusText: ""
    property bool pointerInside: false
    readonly property bool split: root.secondaryIconName !== ""
    readonly property bool pointerSecondary: root.split && mouseArea.mouseY >= root.height / 2
    readonly property int boxSize: 38
    readonly property bool containingWindowVisible: !!(root.Window
        && root.Window.window
        && root.Window.window.visible)
    readonly property string effectiveTooltipText: root.pointerSecondary
        ? root.secondaryStatusText
        : (root.statusText !== ""
            ? root.statusText
            : (WidgetRegistry.label(root.widgetName) || root.widgetName))

    signal activated(string name)
    signal wheelDelta(int angleDelta, bool secondary)
    signal rightClicked(bool secondary)

    Connections {
        target: root.Window ? root.Window.window : null

        function onVisibleChanged() {
            if (!root.containingWindowVisible)
                root.pointerInside = false;
        }
    }

    width: parent ? parent.width : ThemeModule.Theme.sidebarIconSize
    height: box.height + ThemeModule.Theme.sidebarIconSize - root.boxSize
    color: "transparent"

    Accessible.role: Accessible.Button
    Accessible.name: WidgetRegistry.label(root.widgetName) || root.widgetName
    Accessible.description: root.split ? root.statusText + ", " + root.secondaryStatusText : root.statusText
    Accessible.onPressAction: if (root.enabled) root.activated(root.widgetName)

    Rectangle {
        id: box
        anchors.centerIn: parent
        width: root.boxSize
        height: root.split ? root.boxSize * 2 - ThemeModule.Theme.spacingMedium : root.boxSize
        radius: ThemeModule.Theme.borderRadiusSmall
        color: root.active ? ThemeModule.Theme.selectedFill : "transparent"
        border.width: root.active ? ThemeModule.Theme.borderWidth : 0
        border.color: ThemeModule.Theme.selectedBorder

        Column {
            anchors.fill: parent

            Repeater {
                model: root.split ? [root.iconName, root.secondaryIconName] : [root.iconName]

                delegate: Rectangle {
                    id: half

                    required property string modelData
                    required property int index
                    readonly property bool hovered: root.pointerInside && root.pointerSecondary === (half.index === 1)

                    width: box.width
                    height: box.height / (root.split ? 2 : 1)
                    radius: ThemeModule.Theme.borderRadiusSmall
                    color: half.hovered && (root.split || !root.active) ? ThemeModule.Theme.cardHover : "transparent"

                    Components.AppIcon {
                        name: half.modelData
                        size: root.split ? ThemeModule.Theme.iconSizeMedium : ThemeModule.Theme.iconSizeLarge
                        iconColor: root.active
                            ? ThemeModule.Theme.accent
                            : (half.hovered ? ThemeModule.Theme.text : ThemeModule.Theme.subtextBright)
                        anchors.centerIn: parent
                        visible: half.modelData !== ""
                        opacity: root.enabled ? 1 : ThemeModule.Theme.disabledOpacity
                    }
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - ThemeModule.Theme.spacingMedium
            height: ThemeModule.Theme.separatorThickness
            color: ThemeModule.Theme.separator
            visible: root.split
        }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: -6
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 18
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
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: root.pointerInside = true
        onExited: root.pointerInside = false
        onCanceled: root.pointerInside = false
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                root.rightClicked(root.pointerSecondary);
                return;
            }
            if (!root.active)
                Services.EffectsService.picked(box, mouseArea);
            root.activated(root.widgetName);
        }
        onWheel: function(wheel) {
            root.wheelDelta(wheel.angleDelta.y, root.pointerSecondary)
        }
    }
}
