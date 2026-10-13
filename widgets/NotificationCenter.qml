pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Notifications" + (notifList.length > 0 ? " (" + notifList.length + ")" : "")
    iconName: "bell"

    property var notifList: Services.NotificationService.notificationHistory
    property int maxVisibleNotifications: 3
    property bool presented: false
    property int refreshTick: 0
    property string expandedNotificationId: ""
    readonly property int notificationRowHeight: Math.max(48,
        Math.ceil((ThemeModule.Theme.fontSizeSupporting + ThemeModule.Theme.fontSizeCaption) * 1.25)
            + ThemeModule.Theme.spacingMedium)

    onPresentedChanged: {
        if (root.presented)
            root.refreshTick++;
        else
            root.expandedNotificationId = "";
    }

    function notificationKey(notification) {
        return String(notification && notification.id !== undefined ? notification.id : "");
    }

    function toggleExpanded(notification) {
        var key = root.notificationKey(notification);
        root.expandedNotificationId = root.expandedNotificationId === key ? "" : key;
    }

    Timer {
        interval: 30000
        running: root.presented
        repeat: true
        onTriggered: root.refreshTick++
    }

    function listHeightForRows(rowCount) {
        var rows = Math.max(0, rowCount);
        if (rows === 0) return 0;
        return root.notificationRowHeight * rows + ThemeModule.Theme.spacingTiny * (rows - 1);
    }

    function compactText(value) {
        return String(value || "").replace(/\s+/g, " ").trim();
    }

    function primaryText(notification) {
        var summary = root.compactText(notification.summary);
        if (summary !== "") return summary;

        var body = root.compactText(notification.body);
        if (body !== "") return body;

        return notification.appName || "Notification";
    }

    // The second line: the body when the summary leaves one, else the app.
    function detailText(notification) {
        var summary = root.compactText(notification.summary);
        var body = root.compactText(notification.body);
        if (summary !== "" && body !== "" && body !== summary)
            return body;
        return root.compactText(notification.appName);
    }

    function iconSource(notification) {
        return notification.appIcon ? Quickshell.iconPath(notification.appIcon, true) : "";
    }

    function isInternal(notification) {
        return String(notification.id).indexOf("internal:") === 0;
    }

    headerActions: Row {
        spacing: ThemeModule.Theme.spacingSmall

        Components.InlineActionChip {
            visible: root.notifList.length > 0
            text: "Clear"
            iconName: "bell-clear"
            tone: "neutral"
            onActivated: Services.NotificationService.clearHistory()
        }

        Components.InlineActionChip {
            text: "DND"
            iconName: Services.NotificationService.dndEnabled ? "bell-off" : "bell"
            tone: Services.NotificationService.dndEnabled ? "warning" : "neutral"
            armed: Services.NotificationService.dndEnabled
            onActivated: Services.NotificationService.setDndEnabled(!Services.NotificationService.dndEnabled)
        }
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        ListView {
            width: parent.width
            readonly property int compactHeight: root.listHeightForRows(root.maxVisibleNotifications === -1
                ? root.notifList.length
                : Math.min(root.notifList.length, root.maxVisibleNotifications))
            height: root.expandedNotificationId === ""
                ? compactHeight
                : (root.maxVisibleNotifications === -1
                    ? contentHeight
                    : Math.max(compactHeight, Math.min(contentHeight, 240)))
            clip: true
            spacing: ThemeModule.Theme.spacingTiny
            boundsBehavior: Flickable.StopAtBounds
            model: root.notifList

            Behavior on height {
                NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing }
            }

            ScrollBar.vertical: ScrollBar {
                policy: root.maxVisibleNotifications !== -1 && root.notifList.length > root.maxVisibleNotifications
                    ? ScrollBar.AsNeeded
                    : ScrollBar.AlwaysOff
            }

            delegate: Rectangle {
                id: notificationRow
                required property var modelData
                required property int index
                readonly property bool expanded: root.expandedNotificationId
                    === root.notificationKey(notificationRow.modelData)

                width: ListView.view.width
                height: expanded
                    ? Math.max(root.notificationRowHeight,
                        rowContent.implicitHeight + ThemeModule.Theme.spacingSmall * 2)
                    : root.notificationRowHeight
                radius: ThemeModule.Theme.borderRadiusSmall
                clip: true
                color: notifMouse.containsMouse ? ThemeModule.Theme.cardHover : ThemeModule.Theme.controlFill

                Accessible.role: Accessible.Button
                Accessible.name: root.primaryText(notificationRow.modelData)
                Accessible.description: expanded ? "Collapse notification" : "Read full notification"
                Accessible.onPressAction: root.toggleExpanded(notificationRow.modelData)

                Behavior on height {
                    NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing }
                }

                // Critical notifications keep a red edge in the history too.
                Rectangle {
                    visible: notificationRow.modelData.urgency === 2
                    width: 2
                    height: parent.height
                    color: ThemeModule.Theme.error
                }

                Item {
                    id: sourceIcon
                    readonly property string source: root.iconSource(notificationRow.modelData)
                    x: ThemeModule.Theme.spacingSmall
                    y: notificationRow.expanded
                        ? ThemeModule.Theme.spacingSmall + 1
                        : (root.notificationRowHeight - height) / 2
                    width: ThemeModule.Theme.iconSizeMedium
                    height: width

                    Image {
                        id: sourceImage
                        anchors.fill: parent
                        source: sourceIcon.source
                        sourceSize: Qt.size(parent.width * 2, parent.height * 2)
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                    }

                    Components.SpeshellMark {
                        anchors.centerIn: parent
                        size: ThemeModule.Theme.iconSizeMedium - 2
                        visible: !sourceImage.visible && root.isInternal(notificationRow.modelData)
                    }

                    Components.AppIcon {
                        anchors.centerIn: parent
                        name: "bell"
                        size: ThemeModule.Theme.iconSizeSmall
                        iconColor: ThemeModule.Theme.overlay
                        visible: !sourceImage.visible && !root.isInternal(notificationRow.modelData)
                    }
                }

                Column {
                    id: rowContent
                    anchors {
                        left: sourceIcon.right
                        right: dismissBtn.left
                        top: parent.top
                        leftMargin: ThemeModule.Theme.spacingSmall
                        rightMargin: ThemeModule.Theme.spacingTiny
                        topMargin: notificationRow.expanded
                            ? ThemeModule.Theme.spacingSmall
                            : (root.notificationRowHeight - rowContent.implicitHeight) / 2
                    }
                    spacing: ThemeModule.Theme.spacingMicro

                    Item {
                        width: parent.width
                        height: summaryText.implicitHeight

                        Text {
                            id: summaryText
                            anchors.left: parent.left
                            anchors.right: ageText.left
                            anchors.rightMargin: ThemeModule.Theme.spacingSmall
                            text: root.primaryText(notificationRow.modelData)
                            textFormat: Text.PlainText
                            font.pixelSize: ThemeModule.Theme.fontSizeSupporting
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: ThemeModule.Theme.text
                            elide: Text.ElideRight
                            wrapMode: notificationRow.expanded ? Text.Wrap : Text.NoWrap
                        }

                        Text {
                            id: ageText
                            anchors.right: parent.right
                            anchors.baseline: summaryText.baseline
                            text: root.formatTimeAgo(notificationRow.modelData.time, root.refreshTick)
                            font.pixelSize: ThemeModule.Theme.fontSizeCaption
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.overlay
                        }
                    }

                    Text {
                        width: parent.width
                        text: notificationRow.expanded
                            ? String(notificationRow.modelData.body || root.compactText(notificationRow.modelData.appName)).trim()
                            : root.detailText(notificationRow.modelData)
                        textFormat: Text.PlainText
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.subtext
                        elide: notificationRow.expanded ? Text.ElideNone : Text.ElideRight
                        wrapMode: notificationRow.expanded ? Text.Wrap : Text.NoWrap
                        maximumLineCount: notificationRow.expanded ? 12 : 1
                        visible: text !== ""
                    }

                    Text {
                        width: parent.width
                        visible: notificationRow.expanded && root.compactText(notificationRow.modelData.body) !== ""
                        text: root.compactText(notificationRow.modelData.appName)
                        textFormat: Text.PlainText
                        font.pixelSize: ThemeModule.Theme.fontSizeCaption
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.overlay
                        elide: Text.ElideRight
                    }
                }

                Components.IconButton {
                    id: dismissBtn
                    anchors.right: parent.right
                    anchors.rightMargin: ThemeModule.Theme.spacingTiny
                    anchors.top: parent.top
                    anchors.topMargin: notificationRow.expanded
                        ? ThemeModule.Theme.spacingTiny
                        : (notificationRow.height - height) / 2
                    z: 2
                    iconName: "close"
                    size: ThemeModule.Theme.controlHeightSmall
                    iconSize: ThemeModule.Theme.iconSizeSmall
                    iconColor: containsMouse ? ThemeModule.Theme.error : ThemeModule.Theme.overlay
                    hoverColor: ThemeModule.Theme.alpha(ThemeModule.Theme.error, ThemeModule.Theme.tintStrong)
                    tooltipText: "Dismiss notification"
                    onClicked: Services.NotificationService.removeHistoryAt(notificationRow.index)
                }

                MouseArea {
                    id: notifMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    z: 1
                    onClicked: root.toggleExpanded(notificationRow.modelData)
                }
            }
        }

        Components.EmptyState {
            visible: root.notifList.length === 0
            iconName: Services.NotificationService.dndEnabled ? "bell-off" : "bell"
            title: Services.NotificationService.dndEnabled ? "Do Not Disturb is on" : "All caught up"
            detail: Services.NotificationService.dndEnabled
                ? "Only critical ones pop up; the rest wait here."
                : "New notifications will show up here."
        }
    }

    function formatTimeAgo(date, tick) {
        // 'tick' parameter is unused but creates a QML binding dependency
        // that forces periodic re-evaluation of the time-ago string.
        if (!date) return "";
        var now = new Date();
        var diff = Math.floor((now - date) / 1000);
        if (diff < 60) return "just now";
        if (diff < 3600) return Math.floor(diff / 60) + "m ago";
        if (diff < 86400) return Math.floor(diff / 3600) + "h ago";
        return Math.floor(diff / 86400) + "d ago";
    }
}
