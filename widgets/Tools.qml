pragma ComponentBehavior: Bound

import QtQuick
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

// The installed capture and input tools. A click closes the dashboard or dropdown and
// runs one: dictation starts listening, the others take an area the user drags out, or
// the whole screen from the row's screen button. A running dictation or recording shows
// in its row, and another click finishes it.
Components.Card {
    id: root

    property bool presented: false
    property double now: Date.now()

    onPresentedChanged: if (root.presented) Services.ToolsService.probe()

    function formatElapsed(startedAt) {
        var seconds = Math.max(0, Math.floor((root.now - startedAt) / 1000));
        var rest = seconds % 60;
        return Math.floor(seconds / 60) + ":" + (rest < 10 ? "0" : "") + rest;
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.presented && Services.ToolsService.recording !== null
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Repeater {
            model: Services.ToolsService.tools

            delegate: ToolRow {
                id: row

                required property var modelData

                readonly property var dictation: row.modelData.id === "dictate" ? Services.ToolsService.dictation : null
                readonly property var recording: row.modelData.id === "record" ? Services.ToolsService.recording : null

                width: parent.width
                iconName: row.recording !== null ? "record-stop" : (row.dictation !== null && !Services.ToolsService.listening
                    ? "loader" : row.modelData.iconName)
                busy: row.dictation !== null && !Services.ToolsService.listening
                tone: row.recording !== null ? "error" : (row.dictation !== null ? "info" : "accent")
                running: row.recording !== null || row.dictation !== null
                label: row.recording !== null ? "Recording · " + root.formatElapsed(row.recording.startedAt)
                    : (row.dictation !== null ? row.dictation.detail : row.modelData.label)
                detail: row.recording !== null ? "Click to stop and save"
                    : (Services.ToolsService.listening && row.dictation !== null ? "Click to type it out"
                    : (row.dictation !== null ? "Typing into the focused window next" : row.modelData.detail))
                secondaryIcon: row.dictation !== null ? "close"
                    : (row.modelData.screenMode && row.recording === null ? "display" : "")
                secondaryText: row.dictation !== null ? "Discard" : "Whole screen"
                onActivated: Services.ToolsService.run(row.modelData.id, "")
                onSecondaryActivated: Services.ToolsService.run(row.modelData.id, row.dictation !== null ? "cancel" : "screen")
            }
        }
    }

    component ToolRow: Rectangle {
        id: tile

        property string label: ""
        property string detail: ""
        property string iconName: ""
        property string tone: "accent"
        property bool running: false
        property bool busy: false
        property string secondaryIcon: ""
        property string secondaryText: ""

        readonly property color toneColor: ThemeModule.Theme.toneColor(tile.tone)
        readonly property bool hot: tile.running || (tileMouse.containsMouse && !tile.busy)

        signal activated()
        signal secondaryActivated()

        implicitHeight: Math.max(ThemeModule.Theme.controlHeight, tileText.implicitHeight)
            + ThemeModule.Theme.spacingSmall * 2
        radius: ThemeModule.Theme.borderRadiusSmall
        color: tile.running
            ? ThemeModule.Theme.alpha(tile.toneColor, ThemeModule.Theme.tintStrong)
            : (tile.hot ? ThemeModule.Theme.alpha(tile.toneColor, ThemeModule.Theme.tintSubtle) : ThemeModule.Theme.controlFill)
        border.width: ThemeModule.Theme.borderWidth
        border.color: tile.running
            ? ThemeModule.Theme.alpha(tile.toneColor, ThemeModule.Theme.tintOutlineStrong)
            : (tile.hot ? ThemeModule.Theme.alpha(tile.toneColor, ThemeModule.Theme.tintOutline) : "transparent")

        Behavior on color {
            ColorAnimation { duration: ThemeModule.Theme.animDurationFast }
        }

        Accessible.role: Accessible.Button
        Accessible.name: tile.label
        Accessible.description: tile.detail
        Accessible.onPressAction: if (!tile.busy) tile.activated()

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: tile.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: if (!tile.busy) tile.activated()
        }

        Rectangle {
            id: disc
            anchors.left: parent.left
            anchors.leftMargin: ThemeModule.Theme.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            width: ThemeModule.Theme.controlHeight
            height: width
            radius: width / 2
            color: ThemeModule.Theme.alpha(tile.hot ? tile.toneColor : ThemeModule.Theme.overlay,
                tile.hot ? ThemeModule.Theme.tintStrong : ThemeModule.Theme.tintSubtle)

            Components.AppIcon {
                id: discIcon
                anchors.centerIn: parent
                name: tile.iconName
                size: ThemeModule.Theme.iconSizeMedium
                iconColor: tile.hot ? tile.toneColor : ThemeModule.Theme.subtextBright

                RotationAnimator on rotation {
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                    running: tile.busy
                    onRunningChanged: if (!running) discIcon.rotation = 0
                }
            }
        }

        Column {
            id: tileText
            anchors.left: disc.right
            anchors.leftMargin: ThemeModule.Theme.spacingSmall
            anchors.right: secondary.visible ? secondary.left : parent.right
            anchors.rightMargin: ThemeModule.Theme.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            spacing: ThemeModule.Theme.spacingMicro

            Text {
                width: parent.width
                text: tile.label
                color: ThemeModule.Theme.text
                font.pixelSize: ThemeModule.Theme.fontSizeNormal
                font.family: ThemeModule.Theme.fontFamily
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: tile.detail
                color: tile.running ? tile.toneColor : ThemeModule.Theme.subtext
                font.pixelSize: ThemeModule.Theme.fontSizeCaption
                font.family: ThemeModule.Theme.fontFamily
                elide: Text.ElideRight
            }
        }

        Components.IconButton {
            id: secondary
            anchors.right: parent.right
            anchors.rightMargin: ThemeModule.Theme.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            visible: tile.secondaryIcon !== ""
            size: ThemeModule.Theme.controlHeight
            iconName: tile.secondaryIcon
            iconSize: ThemeModule.Theme.iconSizeSmall
            iconColor: secondary.containsMouse ? tile.toneColor : ThemeModule.Theme.subtextBright
            hoverColor: ThemeModule.Theme.alpha(tile.toneColor, ThemeModule.Theme.tintStrong)
            tooltipText: tile.secondaryText
            onClicked: tile.secondaryActivated()
        }
    }
}
