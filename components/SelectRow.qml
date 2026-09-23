import QtQuick
import "../theme" as ThemeModule
import "." as Components

Rectangle {
    id: root

    property string label: ""
    property string value: ""
    property int valueMaxWidth: 180
    property string indicatorIconName: "chevron-down"
    signal activated()

    width: parent ? parent.width : 300
    implicitHeight: Math.max(ThemeModule.Theme.controlHeight, Math.max(labelText.implicitHeight, valueRow.implicitHeight)
        + ThemeModule.Theme.spacingSmall * 2)
    height: implicitHeight
    radius: ThemeModule.Theme.borderRadiusSmall
    opacity: root.enabled ? 1.0 : ThemeModule.Theme.disabledOpacity
    color: selectMouse.containsMouse && root.enabled
        ? ThemeModule.Theme.controlFill
        : "transparent"

    Accessible.role: Accessible.Button
    Accessible.name: root.label
    Accessible.description: root.value
    Accessible.onPressAction: {
        if (root.enabled)
            root.activated();
    }

    Text {
        id: labelText

        text: root.label
        font.pixelSize: ThemeModule.Theme.fontSizeSmall
        font.family: ThemeModule.Theme.fontFamily
        color: ThemeModule.Theme.subtext
        anchors.left: parent.left
        anchors.leftMargin: ThemeModule.Theme.spacingSmall
        anchors.right: valueRow.left
        anchors.rightMargin: ThemeModule.Theme.spacingSmall
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
    }

    Row {
        id: valueRow

        anchors.right: parent.right
        anchors.rightMargin: ThemeModule.Theme.spacingSmall
        anchors.verticalCenter: parent.verticalCenter
        spacing: ThemeModule.Theme.spacingTiny

        Text {
            width: Math.min(root.valueMaxWidth, implicitWidth)
            text: root.value
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            font.bold: true
            color: ThemeModule.Theme.text
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }

        Components.AppIcon {
            name: root.indicatorIconName
            size: ThemeModule.Theme.iconSizeTiny
            iconColor: ThemeModule.Theme.subtext
            anchors.verticalCenter: parent.verticalCenter
            visible: root.indicatorIconName !== ""
        }
    }

    MouseArea {
        id: selectMouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.activated()
    }
}
