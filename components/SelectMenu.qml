pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Templates as T
import "." as Components
import "../services" as Services
import "../theme" as ThemeModule

// Dropdown button that shows the current option's label ({ value, label }) and opens
// a menu of the rest. Unlisted values show fallbackLabel.
Rectangle {
    id: root

    property var options: []
    property var currentValue: undefined
    property string fallbackLabel: currentValue === undefined || currentValue === null
        ? ""
        : String(currentValue)
    property int maxWidth: 200

    signal valueSelected(var selectedValue)

    readonly property string currentLabel: {
        for (var i = 0; i < root.options.length; i++) {
            if (root.options[i].value === root.currentValue)
                return String(root.options[i].label);
        }
        return root.fallbackLabel;
    }
    readonly property bool hovered: selectMouse.containsMouse && root.enabled

    implicitWidth: Math.min(root.maxWidth,
        valueText.implicitWidth + ThemeModule.Theme.iconSizeTiny + ThemeModule.Theme.spacingTiny
            + ThemeModule.Theme.spacingSmall * 2)
    implicitHeight: Math.max(ThemeModule.Theme.controlHeightSmall, valueText.implicitHeight + ThemeModule.Theme.spacingTiny * 2)
        + ThemeModule.Theme.spacingMicro * 2
    width: implicitWidth
    height: implicitHeight
    radius: ThemeModule.Theme.borderRadius
    opacity: root.enabled ? 1.0 : ThemeModule.Theme.disabledOpacity
    color: root.hovered || selectMenu.opened ? ThemeModule.Theme.cardHover : ThemeModule.Theme.controlFill
    border.width: ThemeModule.Theme.borderWidth
    border.color: selectMenu.opened ? ThemeModule.Theme.selectedBorder : ThemeModule.Theme.controlBorder

    Accessible.role: Accessible.ComboBox
    Accessible.name: root.currentLabel
    Accessible.onPressAction: {
        if (root.enabled)
            selectMenu.open();
    }

    Text {
        id: valueText

        anchors.left: parent.left
        anchors.leftMargin: ThemeModule.Theme.spacingSmall
        anchors.right: chevron.left
        anchors.rightMargin: ThemeModule.Theme.spacingTiny
        anchors.verticalCenter: parent.verticalCenter
        text: root.currentLabel
        font.pixelSize: ThemeModule.Theme.fontSizeSmall
        font.family: ThemeModule.Theme.fontFamily
        font.bold: true
        color: ThemeModule.Theme.text
        elide: Text.ElideRight
    }

    Components.AppIcon {
        id: chevron

        anchors.right: parent.right
        anchors.rightMargin: ThemeModule.Theme.spacingSmall
        anchors.verticalCenter: parent.verticalCenter
        name: "chevron-down"
        size: ThemeModule.Theme.iconSizeTiny
        iconColor: root.hovered || selectMenu.opened ? ThemeModule.Theme.text : ThemeModule.Theme.subtext
        rotation: selectMenu.opened ? 180 : 0

        Behavior on rotation {
            NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing }
        }
    }

    MouseArea {
        id: selectMouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: selectMenu.open()
    }

    Components.PopupMenu {
        id: selectMenu

        x: root.width - width
        y: root.height + ThemeModule.Theme.spacingTiny
        modal: true
        focus: true
        closePolicy: T.Popup.CloseOnPressOutside | T.Popup.CloseOnEscape

        Instantiator {
            model: root.options

            delegate: Components.PopupMenuItem {
                required property var modelData
                focusPolicy: Qt.ClickFocus

                text: String(modelData.label)
                selectable: true
                selected: modelData.value === root.currentValue
                enabled: root.enabled
                onTriggered: {
                    if (modelData.value !== root.currentValue)
                        Services.EffectsService.picked(root, null);
                    root.valueSelected(modelData.value);
                }
            }

            onObjectAdded: function(index, object) {
                selectMenu.insertItem(index, object);
            }
            onObjectRemoved: function(index, object) {
                selectMenu.removeItem(object);
            }
        }
    }
}
