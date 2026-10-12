pragma ComponentBehavior: Bound
import QtQuick
import "../theme" as ThemeModule

Column {
    id: root

    property bool presented: false

    width: parent ? parent.width : 0
    spacing: ThemeModule.Theme.spacingXL

    Workspaces {
        width: parent.width
        presented: root.presented
    }

    NowPlaying {
        width: parent.width
        presented: root.presented
    }

    NotificationCenter {
        width: parent.width
        presented: root.presented
    }
}
