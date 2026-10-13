import QtQuick
import "../theme" as ThemeModule

// A labelled group of device rows: title, count, and an optional status on the right.
Item {
    id: root

    property string title: ""
    property int count: 0
    property string status: ""
    property bool statusActive: false

    width: parent ? parent.width : 300
    implicitHeight: Math.max(22, sectionRow.implicitHeight + ThemeModule.Theme.spacingTiny)
    height: implicitHeight

    Row {
        id: sectionRow

        anchors.verticalCenter: parent.verticalCenter
        spacing: ThemeModule.Theme.spacingSmall

        Text {
            text: root.title
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            font.bold: true
            color: ThemeModule.Theme.subtext
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            visible: root.count > 0
            radius: ThemeModule.Theme.borderRadiusSmall
            height: Math.max(16, countText.implicitHeight + ThemeModule.Theme.spacingTiny)
            width: countText.width + 10
            color: ThemeModule.Theme.alpha(ThemeModule.Theme.overlay, ThemeModule.Theme.tintStrong)
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: countText
                anchors.centerIn: parent
                text: root.count
                font.pixelSize: ThemeModule.Theme.fontSizeMicro
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.status
        font.pixelSize: ThemeModule.Theme.fontSizeCaption
        font.family: ThemeModule.Theme.fontFamily
        color: root.statusActive ? ThemeModule.Theme.accent : ThemeModule.Theme.overlay
        visible: text !== ""
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: ThemeModule.Theme.separatorThickness
        color: ThemeModule.Theme.controlFill
    }
}
