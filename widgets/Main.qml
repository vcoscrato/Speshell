pragma ComponentBehavior: Bound
import QtQuick
import "../theme" as ThemeModule

Column {
    id: root

    property bool dashboardActive: true
    property alias maxVisibleNotifications: notifications.maxVisibleNotifications

    width: parent ? parent.width : 0
    spacing: ThemeModule.Theme.spacingXL

    NowPlaying {
        width: parent.width
        dashboardActive: root.dashboardActive
    }

    NotificationCenter {
        id: notifications
        width: parent.width
    }
}
