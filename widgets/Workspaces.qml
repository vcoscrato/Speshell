pragma ComponentBehavior: Bound
import QtQuick
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

// The focused monitor's workspaces, each with the icons of the apps on it. Click one
// to show it under the dashboard; hover one to read its last focused window's title.
Components.Card {
    id: root
    title: "Workspaces"
    iconName: "apps"

    property bool presented: false
    readonly property int columns: 3
    property string hoveredTitle: ""

    onPresentedChanged: if (root.presented) Services.WorkspaceService.refresh()
    Component.onCompleted: if (root.presented) Services.WorkspaceService.refresh()

    headerActions: Text {
        width: Math.min(implicitWidth, root.width * 0.6)
        text: root.hoveredTitle
        elide: Text.ElideRight
        font.pixelSize: ThemeModule.Theme.fontSizeCaption
        font.family: ThemeModule.Theme.fontFamily
        color: ThemeModule.Theme.subtext
    }

    Flow {
        id: grid
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Repeater {
            model: Services.WorkspaceService.workspaces

            delegate: Rectangle {
                id: tile

                required property var modelData
                readonly property bool active: tile.modelData.active
                readonly property var apps: tile.modelData.apps
                readonly property int iconSize: ThemeModule.Theme.iconSizeMedium
                // As many icons as fit after the name; a "+n" takes the last slot when
                // there are more.
                readonly property int slots: Math.max(1, Math.floor((tile.width - label.width
                    - ThemeModule.Theme.spacingSmall * 3 + ThemeModule.Theme.spacingTiny)
                    / (tile.iconSize + ThemeModule.Theme.spacingTiny)))
                readonly property int shown: tile.apps.length > tile.slots ? tile.slots - 1 : tile.apps.length

                width: Math.floor((grid.width - grid.spacing * (root.columns - 1)) / root.columns)
                height: ThemeModule.Theme.controlHeight
                radius: ThemeModule.Theme.borderRadius
                color: tile.active ? ThemeModule.Theme.selectedFill
                    : tileMouse.containsMouse ? ThemeModule.Theme.alpha(ThemeModule.Theme.overlay, ThemeModule.Theme.tintStrong)
                    : ThemeModule.Theme.controlFill
                border.width: ThemeModule.Theme.borderWidth
                border.color: tile.active ? ThemeModule.Theme.selectedBorder : ThemeModule.Theme.controlBorder

                Behavior on color { ColorAnimation { duration: ThemeModule.Theme.animDurationFast } }

                Accessible.role: Accessible.Button
                Accessible.name: "Workspace " + tile.modelData.name
                    + (tile.modelData.title !== "" ? ", " + tile.modelData.title : "")
                Accessible.onPressAction: tile.show()

                function show() {
                    if (tile.active)
                        return;
                    Services.EffectsService.picked(tile);
                    Services.WorkspaceService.focusWorkspace(tile.modelData.id);
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: ThemeModule.Theme.spacingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: ThemeModule.Theme.spacingSmall

                    Text {
                        id: label
                        anchors.verticalCenter: parent.verticalCenter
                        text: tile.modelData.name
                        font.pixelSize: ThemeModule.Theme.fontSizeSupporting
                        font.family: ThemeModule.Theme.fontFamily
                        font.bold: true
                        color: tile.active ? ThemeModule.Theme.accent : ThemeModule.Theme.subtextBright
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: ThemeModule.Theme.spacingTiny

                        Repeater {
                            model: tile.apps.slice(0, tile.shown)

                            delegate: Item {
                                id: app

                                required property string modelData
                                readonly property string iconPath: Services.WorkspaceService.iconFor(app.modelData)

                                width: tile.iconSize
                                height: tile.iconSize

                                Image {
                                    id: appIcon
                                    anchors.fill: parent
                                    source: app.iconPath
                                    sourceSize: Qt.size(tile.iconSize * 2, tile.iconSize * 2)
                                    visible: app.iconPath !== "" && status === Image.Ready
                                }

                                Components.AppIcon {
                                    anchors.centerIn: parent
                                    visible: !appIcon.visible
                                    name: "tray-fallback"
                                    size: tile.iconSize
                                    iconColor: ThemeModule.Theme.subtext
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: tile.shown < tile.apps.length
                            text: "+" + (tile.apps.length - tile.shown)
                            font.pixelSize: ThemeModule.Theme.fontSizeCaption
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.subtext
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: tile.apps.length === 0
                            text: "Empty"
                            font.pixelSize: ThemeModule.Theme.fontSizeCaption
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.subtext
                        }
                    }
                }

                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: tile.active ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onContainsMouseChanged: root.hoveredTitle = tileMouse.containsMouse ? tile.modelData.title : ""
                    onClicked: tile.show()
                }
            }
        }
    }
}
