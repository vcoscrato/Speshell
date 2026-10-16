import QtQuick
import "../theme" as ThemeModule
import "." as Components

Item {
    id: root

    default property alias content: contentColumn.data
    property alias pinnedContent: pinnedColumn.data
    property alias headerActions: headerActionsRow.data
    property string title: ""
    property string iconName: ""

    implicitHeight: container.implicitHeight
    implicitWidth: parent ? parent.width : 300

    // Don't animate implicitHeight: under Qt 6.12, animating this clipped card's
    // height over large content (a long Notes preview) segfaults the scene graph
    // renderer in QSGBatchRenderer::prepareAlphaBatches.
    clip: true

    Column {
        id: container
        anchors.fill: parent
        spacing: ThemeModule.Theme.spacingSmall

        // Header (optional)
        Item {
            visible: root.title !== ""
            width: parent.width
            height: visible ? Math.max(20, leftTitleRow.height, headerActionsRow.height) : 0

            Row {
                id: leftTitleRow
                spacing: ThemeModule.Theme.spacingSmall
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Components.AppIcon {
                    name: root.iconName
                    size: ThemeModule.Theme.iconSizeSmall
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
                id: headerActionsRow
                spacing: ThemeModule.Theme.spacingSmall
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Column {
            id: pinnedColumn
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
        }

        Column {
            id: contentColumn
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
        }
    }
}
