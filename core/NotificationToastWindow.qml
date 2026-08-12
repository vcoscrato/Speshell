pragma ComponentBehavior: Bound
// qmllint disable uncreatable-type unqualified unresolved-type
import QtQuick
import Quickshell
import "../services" as Services
import "../theme" as ThemeModule
import "../components" as Components

PanelWindow {

    // ── Prevent focus stealing from games and other apps ──
    // Explicitly non-focusable: the toast must never take keyboard focus.
    focusable: false
    // Don't reserve exclusive screen space for notifications.
    exclusionMode: ExclusionMode.Ignore

    // Anchor to the top right of the screen
    anchors {
        top: true
        right: true
    }
    
    margins {
        top: ThemeModule.Theme.spacingLarge
        right: ThemeModule.Theme.spacingLarge
    }

    // Transparent background, resizing to fit contents
    color: "transparent"
    implicitWidth: 350
    implicitHeight: toastColumn.height
    
    // Only show if there are active popups
    visible: Services.NotificationService.activePopups.length > 0

    Column {
        id: toastColumn
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium
        
        Repeater {
            model: Services.NotificationService.activePopups

            delegate: Rectangle {
                id: toastCard
                required property var modelData
                readonly property string notificationIcon: modelData.image || (
                    modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, true) : ""
                )

                width: parent.width
                height: toastContent.height + (ThemeModule.Theme.spacingMedium * 2)
                radius: ThemeModule.Theme.borderRadius
                color: toastMouse.containsMouse ? ThemeModule.Theme.cardHover : ThemeModule.Theme.card
                border.color: ThemeModule.Theme.cardHover
                border.width: 1
                clip: true
                
                // Add an entrance animation
                scale: 0.95
                opacity: 0
                Component.onCompleted: {
                    entranceAnim.start()
                }
                
                ParallelAnimation {
                    id: entranceAnim
                    NumberAnimation { target: toastCard; property: "scale"; to: 1.0; duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutBack }
                    NumberAnimation { target: toastCard; property: "opacity"; to: 1.0; duration: ThemeModule.Theme.animDuration }
                }

                Behavior on color {
                    ColorAnimation { duration: ThemeModule.Theme.animDuration }
                }

                // Click anywhere on the toast background to dismiss.
                MouseArea {
                    id: toastMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: toastCard.modelData.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        Services.NotificationService.activatePopup(toastCard.modelData.popupId)
                    }
                }

                Column {
                    id: toastContent
                    anchors {
                        left: parent.left
                        right: dismissBtn.left
                        top: parent.top
                        margins: ThemeModule.Theme.spacingMedium
                    }
                    spacing: ThemeModule.Theme.spacingSmall

                    Row {
                        spacing: ThemeModule.Theme.spacingTiny

                        Image {
                            width: 18
                            height: 18
                            visible: toastCard.notificationIcon !== ""
                            source: toastCard.notificationIcon
                            sourceSize: Qt.size(18, 18)
                            fillMode: Image.PreserveAspectFit
                        }
                        
                        Text {
                            text: toastCard.modelData.appName || "App"
                            textFormat: Text.PlainText
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: ThemeModule.Theme.accent
                        }
                    }

                    Text {
                        text: toastCard.modelData.summary || ""
                        textFormat: Text.PlainText
                        font.pixelSize: ThemeModule.Theme.fontSizeNormal
                        font.family: ThemeModule.Theme.fontFamily
                        font.bold: true
                        color: ThemeModule.Theme.text
                        width: parent.width
                        elide: Text.ElideRight
                        visible: text !== ""
                    }

                    Text {
                        text: toastCard.modelData.body || ""
                        textFormat: Text.PlainText
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.subtext
                        width: parent.width
                        elide: Text.ElideRight
                        maximumLineCount: 3
                        wrapMode: Text.WordWrap
                        visible: text !== ""
                    }

                    Flow {
                        width: parent.width
                        spacing: ThemeModule.Theme.spacingSmall
                        visible: toastCard.modelData.actions.length > 0

                        Repeater {
                            model: toastCard.modelData.actions
                            delegate: Components.InlineActionChip {
                                required property var modelData
                                text: modelData.text
                                tone: "info"
                                onActivated: Services.NotificationService.invokePopupAction(
                                    toastCard.modelData.popupId,
                                    modelData.action
                                )
                            }
                        }
                    }
                }

                Components.IconButton {
                    id: dismissBtn
                    anchors.right: parent.right
                    anchors.rightMargin: ThemeModule.Theme.spacingSmall
                    anchors.top: parent.top
                    anchors.topMargin: ThemeModule.Theme.spacingSmall
                    iconName: "close"
                    size: 24
                    iconSize: 12
                    iconColor: ThemeModule.Theme.overlay
                    hoverColor: Qt.rgba(ThemeModule.Theme.error.r, ThemeModule.Theme.error.g, ThemeModule.Theme.error.b, 0.14)
                    tooltipText: "Dismiss notification"
                    onClicked: {
                        Services.NotificationService.dismissPopup(toastCard.modelData.popupId)
                    }
                }
            }
        }
    }
}
