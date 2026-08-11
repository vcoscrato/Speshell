pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: ""
    property bool presented: false

    readonly property real timerProgress: root.totalSeconds > 0
        ? root.remainingSeconds / root.totalSeconds
        : 0

    property string timeString: ""
    property string dateString: ""
    property bool showColon: true
    property bool timerControlsOpen: false
    property int totalSeconds: 0
    property int remainingSeconds: 0
    property bool timerRunning: false
    property double timerEndsAtMs: 0

    function refreshTime() {
        var now = new Date();
        var h = now.getHours();
        var m = now.getMinutes();
        root.timeString = (h < 10 ? "0" : "") + h + " " + (m < 10 ? "0" : "") + m;
        root.dateString = Qt.formatDate(now, "dddd, MMMM d");
    }

    function scheduleNextTick() {
        clockTimer.stop();
        if (!root.presented)
            return;

        var now = new Date();
        var nextSecond = new Date(now.getTime());
        nextSecond.setMilliseconds(0);
        nextSecond.setSeconds(nextSecond.getSeconds() + 1);
        clockTimer.interval = Math.max(50, nextSecond.getTime() - now.getTime());
        clockTimer.start();
    }

    function formatTimer(seconds) {
        var safeSeconds = Math.max(0, seconds);
        var hours = Math.floor(safeSeconds / 3600);
        var minutes = Math.floor((safeSeconds % 3600) / 60);
        var remainder = safeSeconds % 60;

        if (hours > 0) {
            return hours + ":"
                + (minutes < 10 ? "0" : "") + minutes + ":"
                + (remainder < 10 ? "0" : "") + remainder;
        }

        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder;
    }

    function timerAccentColor() {
        return ThemeModule.Theme.accent;
    }

    function startTimer(minutes) {
        var safeMinutes = Math.max(1, Math.round(Number(minutes) || 0));
        root.totalSeconds = safeMinutes * 60;
        root.remainingSeconds = root.totalSeconds;
        root.timerEndsAtMs = Date.now() + root.totalSeconds * 1000;
        root.timerRunning = true;
        root.timerControlsOpen = false;
        customTimerInput.text = "";
    }

    function stopTimer() {
        root.timerRunning = false;
        root.timerEndsAtMs = 0;
        root.totalSeconds = 0;
        root.remainingSeconds = 0;
    }

    function addTimerMinutes(minutes) {
        var extra = Math.max(1, Math.round(Number(minutes) || 0)) * 60;
        if (!root.timerRunning) {
            root.startTimer(minutes);
            return;
        }

        root.totalSeconds += extra;
        root.timerEndsAtMs += extra * 1000;
        root.updateCountdown();
    }

    function updateCountdown() {
        if (!root.timerRunning)
            return;

        root.remainingSeconds = Math.max(0, Math.ceil((root.timerEndsAtMs - Date.now()) / 1000));
        if (root.remainingSeconds > 0)
            return;

        root.stopTimer();
        timerDoneProc.running = true;
    }

    function startCustomTimer() {
        var customMinutes = parseInt(customTimerInput.text, 10);
        if (!isNaN(customMinutes) && customMinutes > 0) {
            root.startTimer(customMinutes);
        }
    }

    Component.onCompleted: {
        root.refreshTime();
        root.scheduleNextTick();
    }

    Timer {
        id: clockTimer
        interval: 1000
        running: false
        repeat: false
        onTriggered: {
            root.showColon = !root.showColon;
            var now = new Date();
            if (now.getSeconds() === 0) {
                root.refreshTime();
            }
            root.scheduleNextTick();
        }
    }

    Timer {
        id: countdownTimer
        interval: 1000
        running: root.timerRunning
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateCountdown()
    }

    Process {
        id: timerDoneProc
        command: ["notify-send", "-a", "Speshell", "-u", "critical", "Timer Done", "Your timer has finished."]
        running: false
    }

    onPresentedChanged: {
        if (root.presented)
            root.refreshTime();
        root.scheduleNextTick();
    }

    Column {
        width: parent.width
        spacing: root.timerControlsOpen ? ThemeModule.Theme.spacingMedium : ThemeModule.Theme.spacingTiny

        Item {
            width: parent.width
            height: Math.max(clockStage.implicitHeight, timerEntryButton.visible ? timerEntryButton.height : 0)

            Item {
                id: clockStage
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: clockInfoColumn.implicitWidth
                implicitHeight: clockInfoColumn.implicitHeight

                Behavior on width {
                    NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                }

                Column {
                    id: clockInfoColumn
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: ThemeModule.Theme.spacingTiny

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2

                        Text {
                            text: root.timeString.substring(0, 2)
                            font.pixelSize: ThemeModule.Theme.fontSizeHuge
                            font.bold: true
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.text
                        }
                        Text {
                            text: ":"
                            font.pixelSize: ThemeModule.Theme.fontSizeHuge
                            font.bold: true
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.text
                            opacity: root.showColon ? 1.0 : 0.2
                            Behavior on opacity { NumberAnimation { duration: 100 } }
                        }
                        Text {
                            text: root.timeString.substring(3, 5)
                            font.pixelSize: ThemeModule.Theme.fontSizeHuge
                            font.bold: true
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.text
                        }
                    }

                    Text {
                        text: root.dateString
                        font.pixelSize: ThemeModule.Theme.fontSizeNormal
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.text
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Item { height: ThemeModule.Theme.spacingTiny; width: 1 }

                    Rectangle {
                        id: weatherBadge
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: Services.WeatherService.enabled
                            && Services.WeatherService.currentWeatherStr !== "Loading..."
                            && Services.WeatherService.currentWeatherStr !== ""

                        height: 28
                        width: weatherRow.implicitWidth + 24
                        radius: 14
                        color: weatherMouse.containsMouse
                            ? ThemeModule.Theme.cardHover
                            : Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.25)
                        border.width: 1
                        border.color: weatherMouse.containsMouse
                            ? ThemeModule.Theme.accent
                            : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.2)

                        Behavior on color { ColorAnimation { duration: ThemeModule.Theme.animDuration } }
                        Behavior on border.color { ColorAnimation { duration: ThemeModule.Theme.animDuration } }

                        Row {
                            id: weatherRow
                            anchors.centerIn: parent
                            spacing: ThemeModule.Theme.spacingSmall

                            Text {
                                text: Services.WeatherService.currentWeatherStr
                                font.pixelSize: ThemeModule.Theme.fontSizeNormal
                                font.bold: true
                                font.family: ThemeModule.Theme.fontFamily
                                color: ThemeModule.Theme.text
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: weatherMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: Services.WeatherService.fetchWeather()
                            ToolTip.visible: containsMouse
                            ToolTip.text: "Click to refresh weather"
                            ToolTip.delay: 300
                        }
                    }
                }

            }

            Components.IconButton {
                id: timerEntryButton
                anchors.right: parent.right
                anchors.top: parent.top
                size: 34
                iconName: "timer"
                iconSize: 18
                iconColor: root.timerRunning || root.timerControlsOpen
                    ? root.timerAccentColor()
                    : ThemeModule.Theme.subtext
                hoverColor: Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, root.timerRunning ? 0.20 : 0.14)
                tooltipText: root.timerRunning ? "Timer controls" : "Start timer"
                onClicked: root.timerControlsOpen = !root.timerControlsOpen

                Rectangle {
                    width: 5
                    height: 5
                    radius: 3
                    anchors.right: parent.right
                    anchors.rightMargin: 7
                    anchors.top: parent.top
                    anchors.topMargin: 7
                    visible: root.timerRunning
                    color: root.timerAccentColor()
                }
            }
        }

        Item {
            width: parent.width
            height: root.timerRunning ? 50 : 0
            visible: height > 0
            opacity: root.timerRunning ? 1 : 0
            clip: true

            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 140 } }

            Rectangle {
                id: timerDock
                width: Math.min(parent.width, 272)
                height: 42
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 4
                radius: 10
                color: dockMouse.containsMouse
                    ? Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.28)
                    : Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.18)
                border.width: 1
                border.color: Qt.rgba(root.timerAccentColor().r, root.timerAccentColor().g, root.timerAccentColor().b, 0.20)

                Behavior on color { ColorAnimation { duration: ThemeModule.Theme.animDuration } }

                MouseArea {
                    id: dockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: root.timerControlsOpen = !root.timerControlsOpen
                    ToolTip.visible: containsMouse
                    ToolTip.text: "Edit timer"
                    ToolTip.delay: 400
                }

                Row {
                    id: timerDockRow
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 10
                        rightMargin: 8
                        topMargin: 8
                    }
                    height: 26
                    spacing: ThemeModule.Theme.spacingSmall

                    Canvas {
                        id: timerDockDial
                        width: 22
                        height: 22
                        anchors.verticalCenter: parent.verticalCenter

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var accent = root.timerAccentColor();
                            ctx.strokeStyle = Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.38);
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            ctx.arc(11, 11, 8, 0, Math.PI * 2);
                            ctx.stroke();

                            if (root.timerProgress > 0) {
                                ctx.strokeStyle = Qt.rgba(accent.r, accent.g, accent.b, 1);
                                ctx.lineCap = "round";
                                ctx.beginPath();
                                ctx.arc(11, 11, 8, -Math.PI / 2, -Math.PI / 2 + root.timerProgress * Math.PI * 2, false);
                                ctx.stroke();
                            }
                        }

                        Component.onCompleted: requestPaint()
                        onVisibleChanged: requestPaint()

                        Connections {
                            target: root
                            function onTimerProgressChanged() {
                                timerDockDial.requestPaint();
                            }
                        }
                    }

                    Column {
                        width: parent.width - timerDockDial.width - addFiveButton.width - stopSmallButton.width - parent.spacing * 3
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Text {
                            text: root.formatTimer(root.remainingSeconds)
                            font.pixelSize: 14
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: ThemeModule.Theme.text
                        }

                        Text {
                            text: "Focus timer"
                            font.pixelSize: 9
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.overlay
                        }
                    }

                    Rectangle {
                        id: addFiveButton
                        width: 34
                        height: 22
                        radius: 6
                        anchors.verticalCenter: parent.verticalCenter
                        color: addFiveMouse.containsMouse
                            ? Qt.rgba(root.timerAccentColor().r, root.timerAccentColor().g, root.timerAccentColor().b, 0.22)
                            : Qt.rgba(root.timerAccentColor().r, root.timerAccentColor().g, root.timerAccentColor().b, 0.12)
                        border.width: 1
                        border.color: Qt.rgba(root.timerAccentColor().r, root.timerAccentColor().g, root.timerAccentColor().b, 0.36)

                        Text {
                            anchors.centerIn: parent
                            text: "+5"
                            font.pixelSize: 10
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: root.timerAccentColor()
                        }

                        MouseArea {
                            id: addFiveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.addTimerMinutes(5)
                        }
                    }

                    Rectangle {
                        id: stopSmallButton
                        width: 24
                        height: 22
                        radius: 6
                        anchors.verticalCenter: parent.verticalCenter
                        color: stopSmallMouse.containsMouse
                            ? Qt.rgba(ThemeModule.Theme.error.r, ThemeModule.Theme.error.g, ThemeModule.Theme.error.b, 0.20)
                            : "transparent"
                        border.width: 1
                        border.color: Qt.rgba(ThemeModule.Theme.error.r, ThemeModule.Theme.error.g, ThemeModule.Theme.error.b, 0.28)

                        Components.AppIcon {
                            anchors.centerIn: parent
                            name: "close"
                            size: 13
                            iconColor: ThemeModule.Theme.error
                        }

                        MouseArea {
                            id: stopSmallMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.stopTimer()
                        }
                    }
                }

                onVisibleChanged: timerDockDial.requestPaint()
            }
        }

        Rectangle {
            id: timerControlsColumn
            width: parent.width
            visible: root.timerControlsOpen
            height: controlsContent.height + ThemeModule.Theme.spacingMedium * 2
            radius: ThemeModule.Theme.borderRadiusSmall
            color: Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.12)
            border.width: 1
            border.color: Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.18)
            clip: true

            Column {
                id: controlsContent
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: ThemeModule.Theme.spacingMedium
                }
                spacing: ThemeModule.Theme.spacingSmall

                Row {
                    width: parent.width
                    spacing: ThemeModule.Theme.spacingSmall

                    Column {
                        width: parent.width - (root.timerRunning ? stopTimerButton.width + parent.spacing : 0)
                        spacing: 1

                        Text {
                            text: root.timerRunning ? "Focus timer" : "Start focus timer"
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: ThemeModule.Theme.text
                        }

                        Text {
                            text: root.timerRunning
                                ? root.formatTimer(root.remainingSeconds) + " remaining"
                                : "Choose a preset or enter minutes"
                            font.pixelSize: 10
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.subtext
                        }
                    }

                    Components.InlineActionChip {
                        id: stopTimerButton
                        visible: root.timerRunning
                        text: "Stop"
                        iconName: "close"
                        tone: "error"
                        onActivated: root.stopTimer()
                    }
                }

                Flow {
                    width: parent.width
                    spacing: ThemeModule.Theme.spacingSmall

                    Repeater {
                        model: root.timerRunning ? [1, 5, 10] : [5, 10, 25, 45]
                        delegate: Rectangle {
                            id: presetButton
                            required property int modelData
                            readonly property bool primary: !root.timerRunning && modelData === 25
                            readonly property color presetColor: root.timerRunning || primary
                                ? root.timerAccentColor()
                                : ThemeModule.Theme.sky

                            width: 54
                            height: 30
                            radius: 7
                            color: presetMouse.containsMouse
                                ? Qt.rgba(presetColor.r, presetColor.g, presetColor.b, primary ? 0.26 : 0.18)
                                : Qt.rgba(presetColor.r, presetColor.g, presetColor.b, primary ? 0.18 : 0.09)
                            border.width: 1
                            border.color: Qt.rgba(presetColor.r, presetColor.g, presetColor.b, primary ? 0.62 : 0.32)

                            Behavior on color { ColorAnimation { duration: ThemeModule.Theme.animDuration } }

                            Text {
                                anchors.centerIn: parent
                                text: (root.timerRunning ? "+" : "") + presetButton.modelData + "m"
                                font.pixelSize: 11
                                font.family: ThemeModule.Theme.fontFamily
                                font.bold: presetButton.primary
                                color: presetButton.primary ? root.timerAccentColor() : ThemeModule.Theme.text
                            }

                            MouseArea {
                                id: presetMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.timerRunning) root.addTimerMinutes(presetButton.modelData);
                                    else root.startTimer(presetButton.modelData);
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: ThemeModule.Theme.spacingSmall

                    TextField {
                        id: customTimerInput
                        width: parent.width - startTimerButton.width - parent.spacing
                        height: 36
                        background: Rectangle {
                            radius: ThemeModule.Theme.borderRadiusSmall
                            color: Qt.rgba(ThemeModule.Theme.card.r, ThemeModule.Theme.card.g, ThemeModule.Theme.card.b, 0.72)
                            border.width: 1
                            border.color: customTimerInput.activeFocus
                                ? ThemeModule.Theme.accent
                                : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.25)
                        }
                        leftPadding: ThemeModule.Theme.spacingSmall
                        rightPadding: ThemeModule.Theme.spacingSmall
                        color: ThemeModule.Theme.text
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        placeholderText: root.timerRunning ? "Reset minutes" : "Custom minutes"
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 1; top: 720 }
                        onAccepted: root.startCustomTimer()
                    }

                    Components.IconButton {
                        id: startTimerButton
                        size: 36
                        iconSize: 15
                        iconName: "media-play"
                        iconColor: ThemeModule.Theme.text
                        hoverColor: Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.16)
                        tooltipText: root.timerRunning ? "Reset timer" : "Start timer"
                        onClicked: root.startCustomTimer()
                    }
                }
            }
        }
    }
}
