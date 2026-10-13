pragma ComponentBehavior: Bound

import QtQuick
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root

    property bool presented: false
    // The action waiting for a second click; empty when none is.
    property string pendingAction: ""

    readonly property var actions: [
        { id: "sleep", label: "Sleep", detail: "Lock and suspend", iconName: "sleep", tone: "info" },
        { id: "logout", label: "Log out", detail: "End this session", iconName: "logout", tone: "warning" },
        { id: "restart", label: "Restart", detail: "Reboot the system", iconName: "restart", tone: "warning" },
        { id: "poweroff", label: "Power off", detail: "Shut down", iconName: "power", tone: "error" }
    ]

    onPresentedChanged: if (!root.presented) root.cancelConfirmation()

    function canRun(action) {
        if (Services.PowerService.busy)
            return false;
        if (action === "lock" || action === "sleep")
            return Services.PowerService.lockerAvailable;
        return true;
    }

    // The first click arms an action; a second click within the countdown runs it.
    function activate(action) {
        if (!root.canRun(action))
            return;
        if (root.pendingAction !== action) {
            root.pendingAction = action;
            confirmationTimer.restart();
            return;
        }
        // A double-click arms and confirms in one gesture; let it only arm.
        if (confirmationTimer.elapsedMs() < 400)
            return;
        root.cancelConfirmation();
        Services.PowerService.runAction(action);
    }

    function cancelConfirmation() {
        confirmationTimer.stop();
        root.pendingAction = "";
    }

    Timer {
        id: confirmationTimer

        property double startedAt: 0

        function elapsedMs() {
            return Date.now() - confirmationTimer.startedAt;
        }

        interval: 5000
        onRunningChanged: if (running) startedAt = Date.now()
        onTriggered: root.pendingAction = ""
    }

    component PowerTile: Rectangle {
        id: tile

        property string label: ""
        property string detail: ""
        property string iconName: ""
        property string tone: "accent"
        property bool pending: false
        property bool working: false
        property int countdownMs: 0

        readonly property color toneColor: ThemeModule.Theme.toneColor(tile.tone)
        readonly property bool hot: tile.pending || (tileMouse.containsMouse && tile.enabled)

        signal activated()

        implicitHeight: Math.max(ThemeModule.Theme.controlHeight, tileText.implicitHeight)
            + ThemeModule.Theme.spacingMedium * 2
        radius: ThemeModule.Theme.borderRadiusSmall
        clip: true
        opacity: tile.enabled ? 1.0 : ThemeModule.Theme.disabledOpacity
        color: tile.pending
            ? ThemeModule.Theme.alpha(tile.toneColor, ThemeModule.Theme.tintStrong)
            : (tile.hot ? ThemeModule.Theme.alpha(tile.toneColor, ThemeModule.Theme.tintSubtle) : ThemeModule.Theme.controlFill)
        border.width: ThemeModule.Theme.borderWidth
        border.color: tile.pending
            ? ThemeModule.Theme.alpha(tile.toneColor, ThemeModule.Theme.tintOutlineStrong)
            : (tile.hot ? ThemeModule.Theme.alpha(tile.toneColor, ThemeModule.Theme.tintOutline) : "transparent")

        Behavior on color {
            ColorAnimation { duration: ThemeModule.Theme.animDurationFast }
        }

        Accessible.role: Accessible.Button
        Accessible.name: tile.label
        Accessible.description: tile.pending ? "Press again to confirm" : tile.detail
        Accessible.onPressAction: if (tile.enabled) tile.activated()

        Rectangle {
            id: disc
            anchors.left: parent.left
            anchors.leftMargin: ThemeModule.Theme.spacingMedium
            anchors.verticalCenter: parent.verticalCenter
            width: ThemeModule.Theme.controlHeight
            height: width
            radius: width / 2
            color: ThemeModule.Theme.alpha(tile.hot ? tile.toneColor : ThemeModule.Theme.overlay,
                tile.hot ? ThemeModule.Theme.tintStrong : ThemeModule.Theme.tintSubtle)

            Components.AppIcon {
                anchors.centerIn: parent
                name: tile.iconName
                size: ThemeModule.Theme.iconSizeMedium
                iconColor: tile.hot ? tile.toneColor : ThemeModule.Theme.subtextBright
            }
        }

        Column {
            id: tileText
            anchors.left: disc.right
            anchors.leftMargin: ThemeModule.Theme.spacingSmall
            anchors.right: parent.right
            anchors.rightMargin: ThemeModule.Theme.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
            spacing: ThemeModule.Theme.spacingMicro

            Text {
                width: parent.width
                text: tile.working ? "Working…" : (tile.pending ? tile.label + "?" : tile.label)
                color: ThemeModule.Theme.text
                font.pixelSize: ThemeModule.Theme.fontSizeNormal
                font.family: ThemeModule.Theme.fontFamily
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: tile.pending ? "Click again to confirm" : tile.detail
                color: tile.pending ? tile.toneColor : ThemeModule.Theme.subtext
                font.pixelSize: ThemeModule.Theme.fontSizeCaption
                font.family: ThemeModule.Theme.fontFamily
                elide: Text.ElideRight
            }
        }

        // Drains while the confirmation waits.
        Rectangle {
            id: countdown
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            height: 2
            color: tile.toneColor
            visible: tile.pending

            NumberAnimation on width {
                running: tile.pending
                from: tile.width
                to: 0
                duration: tile.countdownMs
            }
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            enabled: tile.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: tile.activated()
        }
    }

    PowerTile {
        width: parent.width
        label: "Lock screen"
        detail: Services.PowerService.lockerChecking
            ? "Checking screen locker"
            : (Services.PowerService.lockerAvailable ? "Secure this session" : "Screen locker unavailable")
        iconName: "lock"
        enabled: root.canRun("lock")
        working: Services.PowerService.activeAction === "lock"
        onActivated: {
            root.cancelConfirmation();
            Services.PowerService.runAction("lock");
        }
    }

    Grid {
        id: actionGrid
        width: parent.width
        columns: 2
        spacing: ThemeModule.Theme.spacingSmall

        Repeater {
            model: root.actions

            delegate: PowerTile {
                required property var modelData

                width: (actionGrid.width - actionGrid.spacing) / 2
                label: modelData.label
                detail: modelData.detail
                iconName: modelData.iconName
                tone: modelData.tone
                enabled: root.canRun(modelData.id)
                pending: root.pendingAction === modelData.id
                working: Services.PowerService.activeAction === modelData.id
                countdownMs: confirmationTimer.interval
                onActivated: root.activate(modelData.id)
            }
        }
    }

    Text {
        visible: Services.PowerService.errorMessage !== ""
        width: parent.width
        text: Services.PowerService.errorMessage
        color: ThemeModule.Theme.error
        font.pixelSize: ThemeModule.Theme.fontSizeSmall
        font.family: ThemeModule.Theme.fontFamily
        wrapMode: Text.WordWrap
    }
}
