pragma ComponentBehavior: Bound

import QtQuick
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root

    property string pendingAction: ""

    readonly property var actions: [
        {
            id: "sleep",
            label: "Sleep",
            detail: "Lock and suspend",
            iconName: "sleep",
            tone: "info"
        },
        {
            id: "logout",
            label: "Log out",
            detail: "End this session",
            iconName: "logout",
            tone: "warning"
        },
        {
            id: "restart",
            label: "Restart",
            detail: "Reboot the system",
            iconName: "restart",
            tone: "warning"
        },
        {
            id: "poweroff",
            label: "Power off",
            detail: "Shut down safely",
            iconName: "power",
            tone: "error"
        }
    ]

    function actionInfo(action) {
        for (var i = 0; i < root.actions.length; i++) {
            if (root.actions[i].id === action)
                return root.actions[i];
        }
        return null;
    }

    function confirmationTitle(action) {
        var info = root.actionInfo(action);
        return info ? info.label + "?" : "Continue?";
    }

    function confirmationDetail(action) {
        if (action === "sleep")
            return "Lock the screen, then suspend this device.";
        if (action === "logout")
            return "Close the Hyprland session. Unsaved work may be lost.";
        if (action === "restart")
            return "Close all applications and restart this device.";
        if (action === "poweroff")
            return "Close all applications and power off this device.";
        return "";
    }

    function canRun(action) {
        if (Services.PowerService.busy)
            return false;
        if (action === "lock" || action === "sleep")
            return Services.PowerService.lockerAvailable;
        return true;
    }

    function requestConfirmation(action) {
        if (!root.canRun(action))
            return;
        root.pendingAction = action;
        confirmationTimer.restart();
    }

    function cancelConfirmation() {
        confirmationTimer.stop();
        root.pendingAction = "";
    }

    function confirmPendingAction() {
        var action = root.pendingAction;
        if (action === "")
            return;
        root.cancelConfirmation();
        Services.PowerService.runAction(action);
    }

    Timer {
        id: confirmationTimer
        interval: 10000
        repeat: false
        onTriggered: root.pendingAction = ""
    }

    Rectangle {
        id: lockAction
        width: parent.width
        height: 68
        radius: ThemeModule.Theme.borderRadiusSmall
        enabled: root.canRun("lock")
        opacity: enabled ? 1.0 : ThemeModule.Theme.disabledOpacity
        color: lockMouse.containsMouse && enabled
            ? ThemeModule.Theme.alpha(ThemeModule.Theme.accent, ThemeModule.Theme.tintStrong)
            : ThemeModule.Theme.controlFill
        border.width: ThemeModule.Theme.borderWidth
        border.color: lockMouse.containsMouse && enabled
            ? ThemeModule.Theme.accent
            : ThemeModule.Theme.controlBorder

        Accessible.role: Accessible.Button
        Accessible.name: "Lock screen"
        Accessible.description: Services.PowerService.lockerAvailable
            ? "Secure this session immediately"
            : "Screen locker unavailable"
        Accessible.onPressAction: if (enabled) Services.PowerService.runAction("lock")

        Row {
            anchors.left: parent.left
            anchors.leftMargin: ThemeModule.Theme.spacingMedium
            anchors.verticalCenter: parent.verticalCenter
            spacing: ThemeModule.Theme.spacingMedium

            Rectangle {
                width: 40
                height: 40
                radius: width / 2
                color: ThemeModule.Theme.alpha(ThemeModule.Theme.accent, ThemeModule.Theme.tintStrong)

                Components.AppIcon {
                    anchors.centerIn: parent
                    name: "lock"
                    size: ThemeModule.Theme.iconSizeMedium
                    iconColor: lockAction.enabled ? ThemeModule.Theme.accent : ThemeModule.Theme.subtext
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: ThemeModule.Theme.spacingMicro

                Text {
                    text: Services.PowerService.activeAction === "lock" ? "Locking…" : "Lock screen"
                    color: ThemeModule.Theme.text
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    font.family: ThemeModule.Theme.fontFamily
                    font.bold: true
                }

                Text {
                    text: Services.PowerService.lockerChecking
                        ? "Checking screen locker"
                        : (Services.PowerService.lockerAvailable
                            ? "Secure this session immediately"
                            : "Screen locker unavailable")
                    color: ThemeModule.Theme.subtext
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                }
            }
        }

        Components.StatusBadge {
            anchors.right: parent.right
            anchors.rightMargin: ThemeModule.Theme.spacingMedium
            anchors.verticalCenter: parent.verticalCenter
            text: Services.PowerService.lockerChecking
                ? "CHECKING"
                : (Services.PowerService.lockerAvailable ? "READY" : "UNAVAILABLE")
            tone: Services.PowerService.lockerAvailable ? "success" : "warning"
        }

        MouseArea {
            id: lockMouse
            anchors.fill: parent
            enabled: lockAction.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: Services.PowerService.runAction("lock")
        }
    }

    Flow {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Repeater {
            model: root.actions

            delegate: Rectangle {
                id: powerAction

                required property var modelData
                readonly property color toneColor: ThemeModule.Theme.toneColor(modelData.tone)

                width: (parent.width - ThemeModule.Theme.spacingSmall) / 2
                height: 72
                radius: ThemeModule.Theme.borderRadiusSmall
                enabled: root.canRun(modelData.id)
                opacity: enabled ? 1.0 : ThemeModule.Theme.disabledOpacity
                color: actionMouse.containsMouse && enabled
                    ? ThemeModule.Theme.alpha(toneColor, ThemeModule.Theme.tintStrong)
                    : ThemeModule.Theme.controlFill
                border.width: root.pendingAction === modelData.id ? 2 : ThemeModule.Theme.borderWidth
                border.color: root.pendingAction === modelData.id
                    ? toneColor
                    : ThemeModule.Theme.controlBorder

                Accessible.role: Accessible.Button
                Accessible.name: modelData.label
                Accessible.description: modelData.detail + ". Requires confirmation."
                Accessible.onPressAction: if (enabled) root.requestConfirmation(modelData.id)

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: ThemeModule.Theme.spacingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: ThemeModule.Theme.spacingSmall

                    Rectangle {
                        width: ThemeModule.Theme.controlHeight
                        height: ThemeModule.Theme.controlHeight
                        radius: width / 2
                        color: ThemeModule.Theme.alpha(powerAction.toneColor, ThemeModule.Theme.tintStrong)

                        Components.AppIcon {
                            anchors.centerIn: parent
                            name: powerAction.modelData.iconName
                            size: ThemeModule.Theme.iconSizeMedium
                            iconColor: powerAction.toneColor
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: ThemeModule.Theme.spacingMicro

                        Text {
                            text: Services.PowerService.activeAction === powerAction.modelData.id
                                ? "Working…"
                                : powerAction.modelData.label
                            color: ThemeModule.Theme.text
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                        }

                        Text {
                            text: powerAction.modelData.detail
                            color: ThemeModule.Theme.subtext
                            font.pixelSize: ThemeModule.Theme.fontSizeCaption
                            font.family: ThemeModule.Theme.fontFamily
                        }
                    }
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    enabled: powerAction.enabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.requestConfirmation(powerAction.modelData.id)
                }
            }
        }
    }

    Rectangle {
        visible: root.pendingAction !== ""
        width: parent.width
        height: visible ? confirmationContent.implicitHeight + ThemeModule.Theme.spacingMedium * 2 : 0
        radius: ThemeModule.Theme.borderRadiusSmall
        color: ThemeModule.Theme.alpha(ThemeModule.Theme.warning, ThemeModule.Theme.tintSubtle)
        border.width: ThemeModule.Theme.borderWidth
        border.color: ThemeModule.Theme.alpha(ThemeModule.Theme.warning, ThemeModule.Theme.tintOutline)

        Behavior on height {
            NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing }
        }

        Column {
            id: confirmationContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: ThemeModule.Theme.spacingMedium
            spacing: ThemeModule.Theme.spacingSmall

            Text {
                width: parent.width
                text: root.confirmationTitle(root.pendingAction)
                color: ThemeModule.Theme.text
                font.pixelSize: ThemeModule.Theme.fontSizeNormal
                font.family: ThemeModule.Theme.fontFamily
                font.bold: true
            }

            Text {
                width: parent.width
                text: root.confirmationDetail(root.pendingAction)
                color: ThemeModule.Theme.subtext
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                wrapMode: Text.WordWrap
            }

            Row {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Components.ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    label: "Cancel"
                    iconName: "close"
                    toneColor: ThemeModule.Theme.subtext
                    onActivated: root.cancelConfirmation()
                }

                Components.ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    label: "Confirm " + (root.actionInfo(root.pendingAction)
                        ? root.actionInfo(root.pendingAction).label.toLowerCase()
                        : "action")
                    iconName: "check"
                    toneColor: root.pendingAction === "poweroff"
                        ? ThemeModule.Theme.error
                        : ThemeModule.Theme.warning
                    onActivated: root.confirmPendingAction()
                }
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
