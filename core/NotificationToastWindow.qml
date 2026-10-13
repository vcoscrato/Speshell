pragma ComponentBehavior: Bound
// qmllint disable uncreatable-type unqualified unresolved-type
import QtQuick
import Quickshell
import "../services" as Services
import "../theme" as ThemeModule
import "../components" as Components

PanelWindow {
    id: root

    property var targetScreen: Services.DashboardService.focusedScreen()

    // Each new toast opens on the focused monitor.
    Connections {
        target: Services.NotificationService

        function onPopupCounterChanged() {
            root.targetScreen = Services.DashboardService.focusedScreen();
        }
    }

    screen: root.targetScreen

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
    
    // Quickshell's type info hides the fields of PanelWindow.margins.
    // qmllint disable missing-property
    margins {
        top: ThemeModule.Theme.spacingLarge
        right: ThemeModule.Theme.spacingLarge
    }
    // qmllint enable missing-property

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

            delegate: Item {
                id: toastCard
                required property var modelData
                // Replaced notifications update the live object in place.
                readonly property var live: modelData.notification
                readonly property bool internal: String(modelData.id).indexOf("internal:") === 0
                readonly property string notificationIcon: modelData.image || (
                    modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, true) : ""
                )
                readonly property color toneColor: modelData.urgency === 2 ? ThemeModule.Theme.error : ThemeModule.Theme.accent

                width: parent.width
                height: toastContent.height + (ThemeModule.Theme.spacingMedium * 2)

                // Top right of the screen: cut toward its center, accent edge on the left.
                Components.Surface {
                    anchors.fill: parent
                    cut: ThemeModule.Theme.spacingMedium
                    cutBottomLeft: true
                    edge: "left"
                    edgeColor: toastCard.toneColor
                    fillColor: toastMouse.containsMouse ? ThemeModule.Theme.card : ThemeModule.Theme.bg

                    Behavior on fillColor {
                        ColorAnimation { duration: ThemeModule.Theme.animDuration }
                    }
                }
                
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
                        leftMargin: ThemeModule.Theme.spacingLarge
                    }
                    spacing: ThemeModule.Theme.spacingSmall

                    Row {
                        spacing: ThemeModule.Theme.spacingSmall

                        Image {
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            visible: toastCard.notificationIcon !== ""
                            source: toastCard.notificationIcon
                            sourceSize: Qt.size(32, 32)
                            fillMode: Image.PreserveAspectFit
                        }

                        Components.SpeshellMark {
                            size: 16
                            anchors.verticalCenter: parent.verticalCenter
                            visible: toastCard.internal && toastCard.notificationIcon === ""
                        }

                        Text {
                            text: toastCard.modelData.appName || "App"
                            textFormat: Text.PlainText
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: ThemeModule.Theme.fontSizeCaption
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 0.8
                            color: toastCard.toneColor
                        }
                    }

                    Text {
                        text: (toastCard.live ? toastCard.live.summary : toastCard.modelData.summary) || ""
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
                        text: (toastCard.live ? toastCard.live.body : toastCard.modelData.body) || ""
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
                    size: ThemeModule.Theme.controlHeightSmall
                    iconSize: ThemeModule.Theme.iconSizeTiny
                    iconColor: ThemeModule.Theme.overlay
                    hoverColor: ThemeModule.Theme.alpha(ThemeModule.Theme.error, ThemeModule.Theme.tintStrong)
                    tooltipText: "Dismiss notification"
                    onClicked: {
                        Services.NotificationService.dismissPopup(toastCard.modelData.popupId)
                    }
                }
            }
        }
    }
}
