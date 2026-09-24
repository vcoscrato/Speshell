pragma ComponentBehavior: Bound
// qmllint disable uncreatable-type unqualified unresolved-type

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

PanelWindow {
    id: root

    property bool shown: false
    property var displayedActivities: []
    property var targetScreen: null
    property double nowMs: Date.now()

    function syncActivities() {
        var active = Services.ActivityService.activities;
        if (active.length > 0) {
            root.displayedActivities = active.slice();
            exitAnimation.stop();
            if (!root.shown) {
                root.targetScreen = Services.DashboardService.focusedScreen();
                activityColumn.opacity = 0;
                activityColumn.scale = 0.97;
                root.shown = true;
                entranceAnimation.restart();
            }
        } else if (root.shown) {
            exitAnimation.restart();
        }
    }

    screen: root.targetScreen
    visible: root.shown && root.targetScreen !== null
    implicitWidth: 390
    implicitHeight: activityColumn.implicitHeight
    color: "transparent"
    focusable: false
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true }
    margins { top: ThemeModule.Theme.spacingLarge }

    WlrLayershell.namespace: "speshell-activity-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Component.onCompleted: root.syncActivities()

    Connections {
        target: Services.ActivityService
        function onActivitiesChanged() { root.syncActivities(); }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.shown
        onTriggered: root.nowMs = Date.now()
    }

    ParallelAnimation {
        id: entranceAnimation

        NumberAnimation {
            target: activityColumn
            property: "opacity"
            to: 1
            duration: ThemeModule.Theme.animDuration
            easing.type: ThemeModule.Theme.animEasing
        }
        NumberAnimation {
            target: activityColumn
            property: "scale"
            to: 1
            duration: ThemeModule.Theme.animDuration
            easing.type: Easing.OutBack
        }
    }

    NumberAnimation {
        id: exitAnimation
        target: activityColumn
        property: "opacity"
        to: 0
        duration: 140
        easing.type: Easing.InCubic
        onStopped: {
            if (Services.ActivityService.activeCount === 0) {
                root.shown = false;
                root.displayedActivities = [];
            }
        }
    }

    Column {
        id: activityColumn

        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Repeater {
            model: root.displayedActivities

            delegate: Rectangle {
                id: activityCard

                required property var modelData
                readonly property color toneColor: ThemeModule.Theme.toneColor(modelData.tone)
                readonly property string elapsed: Services.ActivityService.elapsedText(
                    modelData.startedAt,
                    root.nowMs
                )

                width: activityColumn.width
                implicitHeight: Math.max(70, cardContent.implicitHeight + ThemeModule.Theme.spacingXL)
                height: implicitHeight
                radius: ThemeModule.Theme.borderRadius
                color: ThemeModule.Theme.card
                border.width: ThemeModule.Theme.borderWidth
                border.color: ThemeModule.Theme.alpha(toneColor, ThemeModule.Theme.tintOutline)
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 4
                    color: activityCard.toneColor
                }

                Row {
                    id: cardContent

                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: ThemeModule.Theme.spacingLarge
                        rightMargin: ThemeModule.Theme.spacingLarge
                    }
                    spacing: ThemeModule.Theme.spacingMedium

                    Rectangle {
                        width: 42
                        height: 42
                        radius: ThemeModule.Theme.borderRadiusSmall
                        anchors.verticalCenter: parent.verticalCenter
                        color: ThemeModule.Theme.alpha(activityCard.toneColor, ThemeModule.Theme.tintSubtle)

                        Components.AppIcon {
                            id: activityIcon
                            anchors.centerIn: parent
                            name: activityCard.modelData.iconName
                            size: ThemeModule.Theme.iconSizeLarge
                            iconColor: activityCard.toneColor

                            RotationAnimator on rotation {
                                from: 0
                                to: 360
                                duration: 900
                                loops: Animation.Infinite
                                running: activityCard.modelData.state === "busy"
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: -2
                            anchors.bottomMargin: -2
                            width: 10
                            height: 10
                            radius: 5
                            color: activityCard.toneColor
                            border.width: 2
                            border.color: ThemeModule.Theme.card

                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                running: activityCard.modelData.state === "active"
                                NumberAnimation { to: 0.35; duration: 650; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 650; easing.type: Easing.InOutSine }
                            }
                        }
                    }

                    Column {
                        width: Math.max(
                            80,
                            cardContent.width - 42 - actionRow.width - (cardContent.spacing * 2)
                        )
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: ThemeModule.Theme.spacingTiny

                        Text {
                            width: parent.width
                            text: activityCard.modelData.label
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.pixelSize: ThemeModule.Theme.fontSizeNormal
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: ThemeModule.Theme.text
                        }

                        Text {
                            width: parent.width
                            text: (activityCard.modelData.detail !== ""
                                ? activityCard.modelData.detail + " · "
                                : "") + activityCard.elapsed
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.subtext
                        }
                    }

                    Row {
                        id: actionRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: ThemeModule.Theme.spacingSmall

                        Repeater {
                            model: activityCard.modelData.actions

                            delegate: Components.InlineActionChip {
                                required property var modelData
                                text: modelData.label
                                iconName: modelData.iconName
                                tone: modelData.tone
                                onActivated: Services.ActivityService.requestAction(
                                    activityCard.modelData.provider,
                                    activityCard.modelData.id,
                                    modelData.id
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
