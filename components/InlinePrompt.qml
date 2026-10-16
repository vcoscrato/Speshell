import QtQuick
import "../theme" as ThemeModule
import "." as Components

// An inline field, masked by default, with Connect and Cancel chips. It takes
// focus when shown and forgets what was typed when hidden.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: "Password"
    property bool masked: true
    property bool showActions: true
    property bool autoFocus: true

    signal accepted()
    signal cancelled()

    width: parent ? parent.width : 300
    height: ThemeModule.Theme.controlHeight
    radius: ThemeModule.Theme.borderRadiusSmall
    color: ThemeModule.Theme.card
    border.width: ThemeModule.Theme.borderWidth
    border.color: input.activeFocus ? ThemeModule.Theme.accent : ThemeModule.Theme.cardHover

    onVisibleChanged: {
        if (visible && root.autoFocus)
            root.focusInput();
        else if (!visible)
            input.text = "";
    }

    function focusInput() {
        input.forceActiveFocus();
    }

    TextInput {
        id: input
        anchors.left: parent.left
        anchors.right: promptActions.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: ThemeModule.Theme.spacingSmall
        anchors.rightMargin: ThemeModule.Theme.spacingSmall
        echoMode: root.masked ? TextInput.Password : TextInput.Normal
        color: ThemeModule.Theme.text
        selectionColor: ThemeModule.Theme.accent
        selectedTextColor: ThemeModule.Theme.bg
        font.pixelSize: ThemeModule.Theme.fontSizeSmall
        font.family: ThemeModule.Theme.fontFamily
        clip: true
        onAccepted: root.accepted()
        Keys.onEscapePressed: root.cancelled()

        Component.onCompleted: {
            if (root.visible && root.autoFocus)
                root.focusInput();
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            color: ThemeModule.Theme.overlay
            font: input.font
            visible: input.text === ""
        }
    }

    Row {
        id: promptActions
        visible: root.showActions
        width: root.showActions ? implicitWidth : 0
        anchors.right: parent.right
        anchors.rightMargin: ThemeModule.Theme.spacingTiny
        anchors.verticalCenter: parent.verticalCenter
        spacing: ThemeModule.Theme.spacingTiny

        Components.InlineActionChip {
            text: "Connect"
            tone: "success"
            onActivated: root.accepted()
        }

        Components.InlineActionChip {
            text: "Cancel"
            onActivated: root.cancelled()
        }
    }
}
