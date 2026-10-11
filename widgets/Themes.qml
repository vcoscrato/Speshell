pragma ComponentBehavior: Bound
import QtQuick
import "../components" as Components
import "../services" as Services
import "../services/ThemeProvider.js" as ThemeProvider
import "../theme" as ThemeModule

// Theme picker: the dashboard counterpart of the launcher's !theme and !wall.
Components.Card {
    id: root
    title: "Themes"
    iconName: "palette"

    property bool presented: false

    readonly property bool wallpapersShown: Services.ThemeService.wallpaperEnabled
    readonly property var ownWallpapers: Services.ThemeService.wallpapers.filter(function(wallpaper) {
        return wallpaper.theme === Services.ThemeService.themeId;
    })


    function previewColors(theme) {
        var palette = ThemeModule.Theme.mergePalette(theme.colors);
        return { base: palette.base, border: palette.surface1,
                 dots: [palette.red, palette.yellow, palette.green, palette.blue] };
    }

    // Pick up theme folders added since the last scan.
    onPresentedChanged: if (root.presented) Services.ThemeService.scan()
    Component.onCompleted: Services.ThemeService.scan()

    headerActions: [
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
            tooltipText: "Rescan themes"
            onClicked: Services.ThemeService.scan()
        }
    ]

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Components.SettingRow {
            label: "Draw wallpaper"
            info: "Speshell draws the theme's wallpapers as the desktop background. Turn off to use another wallpaper tool."

            Components.ToggleSwitch {
                checked: root.wallpapersShown
                tooltipText: "Draw wallpaper"
                onToggled: function(newState) { Services.ConfigService.setDrawWallpaper(newState); }
            }
        }

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

        Item { width: 1; height: ThemeModule.Theme.spacingTiny }

        Text {
            text: "Themes"
            font.pixelSize: ThemeModule.Theme.fontSizeCaption
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.subtext
        }
    }

    Column {
        id: themeRows
        width: parent.width
        spacing: ThemeModule.Theme.spacingTiny

        Repeater {
            model: Services.ThemeService.themes

            delegate: Rectangle {
                id: themeRow
                required property var modelData
                readonly property bool current: themeRow.modelData.id === Services.ThemeService.themeId
                readonly property var preview: root.previewColors(themeRow.modelData)

                width: themeRows.width
                height: ThemeModule.Theme.controlHeight + ThemeModule.Theme.spacingSmall * 2
                radius: ThemeModule.Theme.borderRadiusSmall
                color: themeMouse.containsMouse
                    ? ThemeModule.Theme.cardHover
                    : (themeRow.current ? ThemeModule.Theme.selectedFill : ThemeModule.Theme.controlFill)
                border.width: ThemeModule.Theme.borderWidth
                border.color: themeRow.current ? ThemeModule.Theme.selectedBorder : ThemeModule.Theme.controlBorder

                Accessible.role: Accessible.Button
                Accessible.name: "Use theme " + themeRow.modelData.name
                Accessible.description: themeRow.current ? "Current theme" : "Switch theme"
                Accessible.onPressAction: Services.ThemeService.setTheme(themeRow.modelData.id)

                Rectangle {
                    id: swatch
                    anchors.left: parent.left
                    anchors.leftMargin: ThemeModule.Theme.spacingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    width: 48
                    height: ThemeModule.Theme.controlHeight
                    radius: ThemeModule.Theme.borderRadiusSmall
                    color: themeRow.preview.base
                    border.width: ThemeModule.Theme.borderWidth
                    border.color: themeRow.preview.border

                    Row {
                        anchors.centerIn: parent
                        spacing: 3

                        Repeater {
                            model: themeRow.preview.dots

                            delegate: Rectangle {
                                required property var modelData
                                width: 7
                                height: 7
                                radius: 3.5
                                color: modelData
                            }
                        }
                    }
                }

                Text {
                    anchors.left: swatch.right
                    anchors.leftMargin: ThemeModule.Theme.spacingSmall
                    anchors.right: checkIcon.left
                    anchors.rightMargin: ThemeModule.Theme.spacingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: themeRow.modelData.name
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.text
                    elide: Text.ElideRight
                }

                Components.AppIcon {
                    id: checkIcon
                    anchors.right: parent.right
                    anchors.rightMargin: ThemeModule.Theme.spacingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    name: "check"
                    size: ThemeModule.Theme.iconSizeSmall
                    iconColor: ThemeModule.Theme.accent
                    visible: themeRow.current
                }

                MouseArea {
                    id: themeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.ThemeService.setTheme(themeRow.modelData.id)
                }
            }
        }
    }
}
