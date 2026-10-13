import QtQuick
import "../theme" as ThemeModule
import "." as Components

// What a panel shows when it has nothing to list: an icon disc, a title, a hint, and
// optionally the one action that would fill it.
Item {
    id: root

    property string iconName: ""
    property string title: ""
    property string detail: ""
    property string actionLabel: ""
    property string actionIconName: ""
    property bool busy: false

    signal activated()

    // The spinner stops wherever it is; set the icon upright again.
    onBusyChanged: if (!root.busy) statusIcon.rotation = 0

    width: parent ? parent.width : 300
    implicitHeight: column.implicitHeight + ThemeModule.Theme.spacingXL * 2
    height: implicitHeight

    Column {
        id: column
        anchors.centerIn: parent
        width: Math.min(parent.width, 300)
        spacing: ThemeModule.Theme.spacingSmall

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 48
            height: width
            radius: width / 2
            color: ThemeModule.Theme.alpha(root.busy ? ThemeModule.Theme.accent : ThemeModule.Theme.overlay,
                ThemeModule.Theme.tintSubtle)
            border.width: ThemeModule.Theme.borderWidth
            border.color: ThemeModule.Theme.alpha(root.busy ? ThemeModule.Theme.accent : ThemeModule.Theme.overlay,
                ThemeModule.Theme.tintStrong)

            Components.AppIcon {
                id: statusIcon
                anchors.centerIn: parent
                name: root.busy ? "loader" : root.iconName
                size: ThemeModule.Theme.iconSizeLarge
                iconColor: root.busy ? ThemeModule.Theme.accent : ThemeModule.Theme.subtext

                RotationAnimator on rotation {
                    from: 0
                    to: 360
                    duration: 1200
                    loops: Animation.Infinite
                    running: root.busy && root.visible
                }
            }
        }

        Item { width: 1; height: ThemeModule.Theme.spacingTiny }

        Text {
            width: parent.width
            text: root.title
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: ThemeModule.Theme.fontSizeNormal
            font.family: ThemeModule.Theme.fontFamily
            font.weight: Font.DemiBold
            color: ThemeModule.Theme.text
            wrapMode: Text.WordWrap
        }

        Text {
            width: parent.width
            text: root.detail
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.subtext
            wrapMode: Text.WordWrap
            visible: text !== ""
        }

        Item {
            width: 1
            height: ThemeModule.Theme.spacingTiny
            visible: action.visible
        }

        Components.ActionButton {
            id: action
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.actionLabel !== ""
            label: root.actionLabel
            iconName: root.actionIconName
            onActivated: root.activated()
        }
    }
}
