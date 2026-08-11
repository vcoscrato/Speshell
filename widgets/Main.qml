pragma ComponentBehavior: Bound
import QtQuick
import "../theme" as ThemeModule

Column {
    id: root

    property bool presented: false
    property alias maxVisibleNotifications: notifications.maxVisibleNotifications

    width: parent ? parent.width : 0
    spacing: ThemeModule.Theme.spacingXL

    NowPlaying {
        width: parent.width
        presented: root.presented
    }

    NotificationCenter {
        id: notifications
        width: parent.width
        presented: root.presented
    }
}
