pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import "." as Components

Components.SelectRow {
    id: root

    property var options: []
    property var currentValue: undefined
    property string valueRole: "value"
    property string labelRole: "label"
    property string fallbackLabel: currentValue === undefined || currentValue === null
        ? ""
        : String(currentValue)

    signal valueSelected(var selectedValue)

    function optionValue(option) {
        return option ? option[root.valueRole] : undefined;
    }

    function optionLabel(option) {
        return option && option[root.labelRole] !== undefined
            ? String(option[root.labelRole])
            : "";
    }

    function labelForCurrentValue() {
        for (var i = 0; i < root.options.length; i++) {
            if (root.optionValue(root.options[i]) === root.currentValue)
                return root.optionLabel(root.options[i]);
        }
        return root.fallbackLabel;
    }

    value: root.labelForCurrentValue()
    onActivated: selectMenu.open()

    Controls.Menu {
        id: selectMenu

        y: root.height
        width: root.width
        modal: true
        focus: true
        closePolicy: Controls.Popup.CloseOnPressOutside | Controls.Popup.CloseOnEscape

        Instantiator {
            model: root.options

            delegate: Controls.MenuItem {
                required property var modelData
                focusPolicy: Qt.ClickFocus

                text: root.optionLabel(modelData)
                checkable: true
                checked: root.optionValue(modelData) === root.currentValue
                enabled: root.enabled
                onTriggered: root.valueSelected(root.optionValue(modelData))
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
