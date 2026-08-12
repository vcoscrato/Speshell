pragma ComponentBehavior: Bound
import QtQuick
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Now playing"
    iconName: "media"
    property bool presented: false

    readonly property var player: Services.MediaService.player
    readonly property bool hasPlayer: Services.MediaService.hasPlayer

    onPresentedChanged: Services.MediaService.setViewPresented(root.presented)
    Component.onCompleted: Services.MediaService.setViewPresented(root.presented)
    Component.onDestruction: Services.MediaService.setViewPresented(false)

    // Show the widget: if we have a player show controls,
    // otherwise show a "waiting" message so user can see the widget is alive
    visible: true

    // ── No player fallback — compact one-liner ──
    Row {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall
        visible: !root.hasPlayer

        Components.AppIcon {
            name: "media"
            size: 18
            iconColor: ThemeModule.Theme.overlay
            opacity: 0.5
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: "No media playing"
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.overlay
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── Player content ───────────────────────
    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall
        visible: root.hasPlayer

        Row {
            width: parent.width
            spacing: ThemeModule.Theme.spacingMedium

            // ── Album art ────────────────────────
            Rectangle {
                width: 80
                height: 80
                radius: ThemeModule.Theme.borderRadiusSmall
                color: ThemeModule.Theme.surface2
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: source !== ""
                }

                // Fallback icon
                Components.AppIcon {
                    anchors.centerIn: parent
                    name: "media"
                    size: 32
                    iconColor: ThemeModule.Theme.overlay
                    visible: !root.player || !root.player.trackArtUrl || root.player.trackArtUrl === ""
                }
            }

            // ── Track info + controls ────────────
            Column {
                width: parent.width - 80 - ThemeModule.Theme.spacingMedium
                spacing: ThemeModule.Theme.spacingTiny

                // Title
                Text {
                    text: root.player ? (root.player.trackTitle || "No Track") : "No Track"
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    font.bold: true
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.text
                    width: parent.width
                    elide: Text.ElideRight
                }

                // Artist
                Text {
                    text: root.player ? (root.player.trackArtist || "") : ""
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.subtext
                    width: parent.width
                    elide: Text.ElideRight
                }

                // Album
                Text {
                    text: root.player ? (root.player.trackAlbum || "") : ""
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.overlay
                    width: parent.width
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                Item { width: 1; height: ThemeModule.Theme.spacingTiny }

                // ── Playback controls ────────────
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: ThemeModule.Theme.spacingMedium

                    Components.IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: "media-previous"
                        iconSize: ThemeModule.Theme.fontSizeLarge
                        tooltipText: "Previous track"
                        onClicked: { if (root.player) root.player.previous() }
                    }

                    Components.IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: Services.MediaService.playing ? "media-pause" : "media-play"
                        iconSize: ThemeModule.Theme.fontSizeXL
                        size: 44
                        iconColor: ThemeModule.Theme.accent
                        iconXOffset: Services.MediaService.playing ? 0 : 2
                        tooltipText: Services.MediaService.playing
                            ? "Pause"
                            : "Play"
                        onClicked: {
                            if (root.player) root.player.togglePlaying()
                        }
                    }

                    Components.IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: "media-next"
                        iconSize: ThemeModule.Theme.fontSizeLarge
                        tooltipText: "Next track"
                        onClicked: { if (root.player) root.player.next() }
                    }
                }
            }
        }

        // ── Progress bar ─────────────────────────
        Column {
            width: parent.width
            spacing: 2
            visible: root.player && root.player.length > 0

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: ThemeModule.Theme.surface2

                Accessible.role: Accessible.Slider
                Accessible.name: "Track position"
                Accessible.description: root.player
                    ? root.formatTime(Services.MediaService.displayedPosition)
                        + " of " + root.formatTime(root.player.length)
                    : ""

                Rectangle {
                    width: (root.player && root.player.length > 0)
                        ? (Services.MediaService.displayedPosition / root.player.length) * parent.width
                        : 0
                    height: parent.height
                    radius: 2
                    color: ThemeModule.Theme.accent
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        if (root.player && root.player.length > 0) {
                            var ratio = mouse.x / parent.width;
                            Services.MediaService.seek(ratio * root.player.length);
                        }
                    }
                }
            }

            Row {
                width: parent.width

                Text {
                    id: elapsedText
                    text: root.player ? root.formatTime(Services.MediaService.displayedPosition) : "0:00"
                    font.pixelSize: 10
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.overlay
                }

                Item {
                    width: Math.max(0, parent.width - elapsedText.width - totalText.width)
                    height: 1
                }

                Text {
                    id: totalText
                    text: root.player ? root.formatTime(root.player.length) : "0:00"
                    font.pixelSize: 10
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.overlay
                }
            }
        }
    }

    function formatTime(ms) {
        if (!ms || ms <= 0) return "0:00";
        var totalSec = Math.floor(ms / 1000000); // MPRIS uses microseconds
        var min = Math.floor(totalSec / 60);
        var sec = totalSec % 60;
        return min + ":" + (sec < 10 ? "0" : "") + sec;
    }
}
