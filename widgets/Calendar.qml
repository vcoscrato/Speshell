pragma ComponentBehavior: Bound
import QtQuick
import "../components" as Components
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: ""

    property int displayYear: new Date().getFullYear()
    property int displayMonth: new Date().getMonth()

    readonly property var monthNames: ["January", "February", "March", "April", "May", "June",
                                        "July", "August", "September", "October", "November", "December"]
    readonly property var dayNames: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    property int today: new Date().getDate()
    property int todayMonth: new Date().getMonth()
    property int todayYear: new Date().getFullYear()
    property bool dashboardActive: true

    function refreshToday() {
        var now = new Date();
        root.today = now.getDate();
        root.todayMonth = now.getMonth();
        root.todayYear = now.getFullYear();
    }

    onDashboardActiveChanged: {
        if (root.dashboardActive) root.refreshToday();
    }

    // Refresh at midnight if dashboard stays open
    Timer {
        id: midnightRefreshTimer
        interval: 60000
        running: root.dashboardActive
        repeat: true
        onTriggered: root.refreshToday()
    }

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function firstDayOfMonth(year, month) {
        return new Date(year, month, 1).getDay();
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        // ── Month navigation ─────────────────
        Row {
            width: parent.width

            Components.IconButton {
                iconName: "chevron-left"
                size: 28
                iconSize: ThemeModule.Theme.fontSizeNormal
                tooltipText: "Previous month"
                onClicked: {
                    if (root.displayMonth === 0) {
                        root.displayMonth = 11;
                        root.displayYear--;
                    } else {
                        root.displayMonth--;
                    }
                }
            }

            Item {
                width: parent.width - 56
                height: 28

                Text {
                    anchors.centerIn: parent
                    text: root.monthNames[root.displayMonth] + " " + root.displayYear
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    font.bold: true
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.text
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Components.IconButton {
                iconName: "chevron-right"
                size: 28
                iconSize: ThemeModule.Theme.fontSizeNormal
                tooltipText: "Next month"
                onClicked: {
                    if (root.displayMonth === 11) {
                        root.displayMonth = 0;
                        root.displayYear++;
                    } else {
                        root.displayMonth++;
                    }
                }
            }
        }

        // ── Day of week headers ──────────────
        Row {
            width: parent.width
            spacing: 0

            Repeater {
                model: root.dayNames
                delegate: Text {
                    required property string modelData

                    width: parent.width / 7
                    text: modelData
                    font.pixelSize: 10
                    font.family: ThemeModule.Theme.fontFamily
                    font.bold: true
                    color: ThemeModule.Theme.overlay
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // ── Calendar grid ────────────────────
        Grid {
            id: calGrid
            columns: 7
            width: parent.width
            spacing: 0

            property int numDays: root.daysInMonth(root.displayYear, root.displayMonth)
            property int firstDay: root.firstDayOfMonth(root.displayYear, root.displayMonth)

            Repeater {
                model: calGrid.firstDay + calGrid.numDays

                delegate: Item {
                    id: dayCell
                    required property int index

                    width: calGrid.width / 7
                    height: 32

                    property int dayNum: dayCell.index - calGrid.firstDay + 1
                    property bool isValid: dayCell.index >= calGrid.firstDay
                    property bool isToday: isValid && dayNum === root.today &&
                                           root.displayMonth === root.todayMonth &&
                                           root.displayYear === root.todayYear

                    Rectangle {
                        anchors.centerIn: parent
                        width: 28
                        height: 28
                        radius: ThemeModule.Theme.borderRadiusSmall
                        color: dayCell.isToday ? ThemeModule.Theme.accent : (dayMouse.containsMouse && dayCell.isValid ? ThemeModule.Theme.cardHover : "transparent")
                        visible: dayCell.isValid

                        Behavior on color {
                            ColorAnimation { duration: ThemeModule.Theme.animDuration }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: dayCell.isValid ? dayCell.dayNum : ""
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: dayCell.isToday
                            color: dayCell.isToday ? ThemeModule.Theme.crust : ThemeModule.Theme.text
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: dayCell.isValid ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                    }
                }
            }
        }

        // ── Today shortcut ───────────────────
        Rectangle {
            width: parent.width
            height: 24
            color: "transparent"
            visible: root.displayMonth !== root.todayMonth || root.displayYear !== root.todayYear

            Row {
                anchors.centerIn: parent
                spacing: ThemeModule.Theme.spacingTiny

                Components.AppIcon {
                    name: "back"
                    size: 14
                    iconColor: ThemeModule.Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Today"
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.displayMonth = root.todayMonth;
                    root.displayYear = root.todayYear;
                }
            }
        }
    }
}
