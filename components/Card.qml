import QtQuick
import "../theme" as ThemeModule
import "." as Components

Rectangle {
    id: root

    default property alias content: contentColumn.data
    property alias contentItem: contentColumn
    property alias pinnedContent: pinnedColumn.data
    property alias headerActions: headerActionsRow.data
    property string title: ""
    property string iconName: ""
    property bool collapsible: false
    property bool collapsed: collapsible

    color: "transparent"
    radius: 0
    border.width: 0

    implicitHeight: container.implicitHeight
    implicitWidth: parent ? parent.width : 300

    Behavior on implicitHeight {
        NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutCubic }
    }

    clip: true

    Column {
        id: container
        anchors.fill: parent
        spacing: ThemeModule.Theme.spacingSmall

        // Header (optional)
        Item {
            visible: root.title !== ""
            width: parent.width
            height: visible ? Math.max(20, leftTitleRow.height, rightControlsRow.height) : 0

            Row {
                id: leftTitleRow
                spacing: ThemeModule.Theme.spacingSmall
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Components.AppIcon {
                    name: root.iconName
                    size: 14
                    iconColor: ThemeModule.Theme.subtext
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.iconName !== ""
                }

                Text {
                    text: root.title
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 0.8
                    color: ThemeModule.Theme.subtext
                }
            }

            Row {
                id: rightControlsRow
                spacing: ThemeModule.Theme.spacingSmall
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    id: headerActionsRow
                    spacing: ThemeModule.Theme.spacingSmall
                    anchors.verticalCenter: parent.verticalCenter
                }

                Components.AppIcon {
                    name: root.collapsed ? "chevron-right" : "chevron-down"
                    iconColor: ThemeModule.Theme.subtext
                    size: 14
                    visible: root.collapsible
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        visible: root.collapsible
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.collapsed = !root.collapsed
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: rightControlsRow.width + ThemeModule.Theme.spacingSmall
                visible: root.collapsible
                cursorShape: root.collapsible ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (root.collapsible) root.collapsed = !root.collapsed
                }
            }
        }


        Column {
            id: pinnedColumn
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
        }

        // Content area
        Column {
            id: contentColumn
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: !root.collapsed
            opacity: root.collapsed ? 0 : 1

            Behavior on opacity {
                NumberAnimation { duration: ThemeModule.Theme.animDuration }
            }
        }
    }
}
