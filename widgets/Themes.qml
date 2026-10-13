pragma ComponentBehavior: Bound
import QtQuick
import "../components" as Components
import "../services" as Services
import "../services/ThemeProvider.js" as ThemeProvider
import "../theme" as ThemeModule

// Theme picker: the dashboard counterpart of the launcher's !theme and !wall. Its
// settings, from drawing the wallpaper to effect speeds, are in Settings' Themes page.
Components.Card {
    id: root
    title: "Themes"
    iconName: "palette"

    property bool presented: false

    readonly property bool wallpapersShown: Services.ThemeService.wallpaperEnabled
    readonly property var ownWallpapers: Services.ThemeService.wallpapers.filter(function(wallpaper) {
        return wallpaper.theme === Services.ThemeService.themeId;
    })

    // Pick up theme folders added since the last scan.
    onPresentedChanged: if (root.presented) Services.ThemeService.scan()
    Component.onCompleted: Services.ThemeService.scan()

    headerActions: [
        Components.IconButton {
            iconName: "config"
            iconSize: ThemeModule.Theme.iconSizeSmall
            size: ThemeModule.Theme.controlHeightSmall
            iconColor: ThemeModule.Theme.subtextBright
            tooltipText: "Wallpaper and effect settings"
            onClicked: {
                Services.DashboardService.settingsPage = "themes";
                Services.DashboardService.openPanel("settings");
            }
        },
        Components.IconButton {
            iconName: "shuffle"
            iconSize: ThemeModule.Theme.iconSizeSmall
            size: ThemeModule.Theme.controlHeightSmall
            iconColor: ThemeModule.Theme.subtextBright
            visible: root.wallpapersShown && root.ownWallpapers.length > 1
            tooltipText: "Another wallpaper from this theme"
            onClicked: Services.ThemeService.shuffle("")
        },
        Components.RefreshButton {
            active: Services.ThemeService.scanning
            tooltipText: "Look for new themes"
            onClicked: Services.ThemeService.scan()
        }
    ]

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Grid {
            id: wallpaperGrid
            visible: root.wallpapersShown && root.ownWallpapers.length > 0
            width: parent.width
            columns: 3
            spacing: ThemeModule.Theme.spacingSmall
            readonly property real cellWidth: (wallpaperGrid.width - wallpaperGrid.spacing * (wallpaperGrid.columns - 1))
                / wallpaperGrid.columns

            Repeater {
                model: root.wallpapersShown ? root.ownWallpapers : []

                delegate: Rectangle {
                    id: wallpaperCell
                    required property var modelData
                    readonly property bool current: wallpaperCell.modelData.path === Services.ThemeService.wallpaper

                    width: wallpaperGrid.cellWidth
                    height: Math.round(wallpaperGrid.cellWidth * 10 / 16)
                    radius: ThemeModule.Theme.borderRadiusSmall
                    color: ThemeModule.Theme.controlFill
                    clip: true

                    Accessible.role: Accessible.Button
                    Accessible.name: "Use wallpaper " + wallpaperCell.modelData.title
                    Accessible.onPressAction: Services.ThemeService.setWallpaper(wallpaperCell.modelData.path)

                    Image {
                        anchors.fill: parent
                        source: ThemeProvider.fileUrl(wallpaperCell.modelData.path)
                        sourceSize: Qt.size(256, 160)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: wallpaperMouse.containsMouse ? ThemeModule.Theme.alpha(ThemeModule.Theme.text, 0.12) : "transparent"
                        border.width: wallpaperCell.current ? 2 : ThemeModule.Theme.borderWidth
                        border.color: wallpaperCell.current ? ThemeModule.Theme.accent : ThemeModule.Theme.controlBorder
                    }

                    MouseArea {
                        id: wallpaperMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.ThemeService.setWallpaper(wallpaperCell.modelData.path)
                    }
                }
            }
        }

        // Divides the theme's wallpapers from the themes; alone, the card title says it.
        Item {
            width: 1
            height: ThemeModule.Theme.spacingTiny
            visible: wallpaperGrid.visible
        }

        Text {
            visible: wallpaperGrid.visible
            text: "Themes"
            font.pixelSize: ThemeModule.Theme.fontSizeCaption
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.subtext
        }
    }

    Grid {
        id: themeTiles
        width: parent.width
        columns: 2
        spacing: ThemeModule.Theme.spacingSmall
        readonly property real cellWidth: (themeTiles.width - themeTiles.spacing * (themeTiles.columns - 1))
            / themeTiles.columns

        Repeater {
            model: Services.ThemeService.themes

            // A tile previews the theme itself: the wallpaper it comes with under a
            // miniature dashboard panel drawn in the theme's own colors.
            delegate: Rectangle {
                id: tile
                required property var modelData
                readonly property bool current: tile.modelData.id === Services.ThemeService.themeId
                readonly property var colors: ThemeModule.Theme.mergePalette(tile.modelData.colors)
                readonly property string wallpaperPath: tile.current
                    ? Services.ThemeService.wallpaper
                    : Services.ThemeService.wallpaperFor(tile.modelData.id)
                readonly property color pCrust: tile.colors.crust
                readonly property color pBase: tile.colors.base
                readonly property color pSurface0: tile.colors.surface0
                readonly property color pSurface1: tile.colors.surface1
                readonly property color pSurface2: tile.colors.surface2
                readonly property color pText: tile.colors.text
                readonly property color pAccent: tile.colors.accent

                width: themeTiles.cellWidth
                height: preview.height + nameRow.height + ThemeModule.Theme.spacingSmall * 2
                radius: ThemeModule.Theme.borderRadius
                color: tileMouse.containsMouse
                    ? ThemeModule.Theme.cardHover
                    : (tile.current ? ThemeModule.Theme.selectedFill : ThemeModule.Theme.controlFill)
                border.width: tile.current ? 2 : ThemeModule.Theme.borderWidth
                border.color: tile.current ? ThemeModule.Theme.accent : ThemeModule.Theme.controlBorder

                Accessible.role: Accessible.Button
                Accessible.name: "Use theme " + tile.modelData.name
                Accessible.description: tile.current ? "Current theme" : "Switch theme"
                Accessible.onPressAction: Services.ThemeService.setTheme(tile.modelData.id)

                Rectangle {
                    id: preview
                    x: ThemeModule.Theme.spacingTiny + 1
                    y: ThemeModule.Theme.spacingTiny + 1
                    width: tile.width - x * 2
                    height: Math.round(preview.width * 10 / 16)
                    radius: ThemeModule.Theme.borderRadiusSmall
                    clip: true
                    gradient: Gradient {
                        GradientStop { position: 0; color: tile.pBase }
                        GradientStop { position: 1; color: tile.pCrust }
                    }

                    Image {
                        anchors.fill: parent
                        visible: tile.wallpaperPath !== ""
                        source: tile.wallpaperPath !== "" ? ThemeProvider.fileUrl(tile.wallpaperPath) : ""
                        sourceSize: Qt.size(320, 200)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    // Miniature dashboard panel: header, a selected row, plain rows,
                    // a slider, and a switch.
                    Rectangle {
                        id: miniPanel
                        readonly property real pad: Math.max(4, Math.round(preview.width * 0.035))
                        readonly property real rowHeight: Math.max(7, Math.round(preview.height * 0.12))
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: miniPanel.pad
                        width: Math.round(preview.width * 0.42)
                        radius: 2
                        color: tile.pBase
                        border.width: 1
                        border.color: tile.pSurface1

                        Column {
                            id: miniColumn
                            anchors.fill: parent
                            anchors.margins: miniPanel.pad
                            spacing: Math.max(2, Math.round(miniPanel.pad * 0.6))

                            Rectangle {
                                width: parent.width * 0.45
                                height: 3
                                radius: 1.5
                                color: ThemeModule.Theme.alpha(tile.pText, 0.75)
                            }

                            Repeater {
                                model: 3

                                delegate: Rectangle {
                                    id: miniRow
                                    required property int index
                                    readonly property bool selected: miniRow.index === 0
                                    width: miniColumn.width
                                    height: miniPanel.rowHeight
                                    radius: 2
                                    color: miniRow.selected ? ThemeModule.Theme.alpha(tile.pAccent, 0.18) : tile.pSurface0
                                    border.width: miniRow.selected ? 1 : 0
                                    border.color: ThemeModule.Theme.alpha(tile.pAccent, 0.7)

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 3
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: miniRow.width * (miniRow.selected ? 0.5 : 0.35 + 0.1 * miniRow.index)
                                        height: 2
                                        radius: 1
                                        color: miniRow.selected ? tile.pAccent : ThemeModule.Theme.alpha(tile.pText, 0.45)
                                    }
                                }
                            }

                            Item {
                                width: parent.width
                                height: 8

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: miniSwitch.left
                                    anchors.rightMargin: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 3
                                    radius: 1.5
                                    color: tile.pSurface2

                                    Rectangle {
                                        width: parent.width * 0.6
                                        height: parent.height
                                        radius: parent.radius
                                        color: tile.pAccent
                                    }
                                }

                                Rectangle {
                                    id: miniSwitch
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 14
                                    height: 8
                                    radius: 4
                                    color: tile.pAccent

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 1
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: tile.pBase
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: nameRow
                    anchors.left: preview.left
                    anchors.right: preview.right
                    anchors.top: preview.bottom
                    anchors.topMargin: ThemeModule.Theme.spacingTiny
                    height: Math.max(nameText.implicitHeight, checkIcon.height) + ThemeModule.Theme.spacingMicro

                    Rectangle {
                        id: accentDot
                        anchors.left: parent.left
                        anchors.leftMargin: ThemeModule.Theme.spacingMicro
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: tile.pAccent
                    }

                    Text {
                        id: nameText
                        anchors.left: accentDot.right
                        anchors.leftMargin: ThemeModule.Theme.spacingSmall - 2
                        anchors.right: checkIcon.visible ? checkIcon.left : parent.right
                        anchors.rightMargin: ThemeModule.Theme.spacingTiny
                        anchors.verticalCenter: parent.verticalCenter
                        text: tile.modelData.name
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        font.weight: tile.current ? Font.DemiBold : Font.Normal
                        color: ThemeModule.Theme.text
                        elide: Text.ElideRight
                    }

                    Components.AppIcon {
                        id: checkIcon
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        name: "check"
                        size: ThemeModule.Theme.iconSizeTiny
                        iconColor: ThemeModule.Theme.accent
                        visible: tile.current
                    }
                }

                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.ThemeService.setTheme(tile.modelData.id)
                }
            }
        }
    }
}
