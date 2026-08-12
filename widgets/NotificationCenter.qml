pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
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
    readonly property int notificationRowHeight: 48

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

    function detailText(notification, tick) {
        var pieces = [];
        var appName = root.compactText(notification.appName || "App");
        var timeAgo = root.formatTimeAgo(notification.time, tick);
        var summary = root.compactText(notification.summary);
        var body = root.compactText(notification.body);

        if (appName !== "") pieces.push(appName);
        if (timeAgo !== "") pieces.push(timeAgo);
        if (summary !== "" && body !== "" && body !== summary) pieces.push(body);

        return pieces.join(" · ");
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
            onActivated: Services.NotificationService.dndEnabled = !Services.NotificationService.dndEnabled
        }
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        ListView {
            id: notificationList
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
                NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutCubic }
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
                        expandedContent.implicitHeight + ThemeModule.Theme.spacingSmall * 2)
                    : root.notificationRowHeight
                radius: ThemeModule.Theme.borderRadiusSmall
                activeFocusOnTab: true
                color: notifMouse.containsMouse
                    ? Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.35)
                    : Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.18)
                border.width: activeFocus ? 2 : 0
                border.color: ThemeModule.Theme.accent

                Accessible.role: Accessible.Button
                Accessible.name: root.primaryText(notificationRow.modelData)
                Accessible.description: expanded ? "Collapse notification" : "Read full notification"
                Accessible.onPressAction: root.toggleExpanded(notificationRow.modelData)

                Keys.onPressed: function(event) {
                    if (event.isAutoRepeat)
                        return;
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        root.toggleExpanded(notificationRow.modelData);
                        event.accepted = true;
                    }
                }

                Behavior on height {
                    NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutCubic }
                }

                Column {
                    id: notifContent
                    anchors {
                        left: parent.left
                        right: dismissBtn.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: ThemeModule.Theme.spacingSmall
                        rightMargin: ThemeModule.Theme.spacingTiny
                    }
                    spacing: 2
                    visible: !notificationRow.expanded

                    Text {
                        width: parent.width
                        text: root.primaryText(notificationRow.modelData)
                        textFormat: Text.PlainText
                        font.pixelSize: 12
                        font.family: ThemeModule.Theme.fontFamily
                        font.bold: true
                        color: ThemeModule.Theme.text
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.detailText(notificationRow.modelData, root.refreshTick)
                        textFormat: Text.PlainText
                        font.pixelSize: 10
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.subtext
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }

                Column {
                    id: expandedContent
                    anchors {
                        left: parent.left
                        right: dismissBtn.left
                        top: parent.top
                        leftMargin: ThemeModule.Theme.spacingSmall
                        rightMargin: ThemeModule.Theme.spacingTiny
                        topMargin: ThemeModule.Theme.spacingSmall
                    }
                    spacing: ThemeModule.Theme.spacingTiny
                    visible: notificationRow.expanded

                    Text {
                        width: parent.width
                        text: root.primaryText(notificationRow.modelData)
                        textFormat: Text.PlainText
                        font.pixelSize: 12
                        font.family: ThemeModule.Theme.fontFamily
                        font.bold: true
                        color: ThemeModule.Theme.text
                        wrapMode: Text.WrapAnywhere
                    }

                    Text {
                        width: parent.width
                        text: root.compactText(notificationRow.modelData.appName || "App")
                            + " · " + root.formatTimeAgo(notificationRow.modelData.time, root.refreshTick)
                        textFormat: Text.PlainText
                        font.pixelSize: 10
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.overlay
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: String(notificationRow.modelData.body || "")
                        textFormat: Text.PlainText
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.subtext
                        wrapMode: Text.WrapAnywhere
                        visible: text !== "" && text !== notificationRow.modelData.summary
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
                    size: 30
                    iconSize: 14
                    iconColor: containsMouse ? ThemeModule.Theme.error : ThemeModule.Theme.overlay
                    hoverColor: Qt.rgba(ThemeModule.Theme.error.r, ThemeModule.Theme.error.g, ThemeModule.Theme.error.b, 0.14)
                    tooltipText: "Dismiss notification"
                    onClicked: Services.NotificationService.removeHistoryAt(notificationRow.index)
                }

                MouseArea {
                    id: notifMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    z: 1
                    onClicked: {
                        notificationRow.forceActiveFocus();
                        root.toggleExpanded(notificationRow.modelData);
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: root.notifList.length === 0
            height: 30

            Text {
                text: "No notifications"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.overlay
                anchors.verticalCenter: parent.verticalCenter
            }
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
