pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: ""
    property bool presented: false

    readonly property bool timerRunning: Services.FocusTimerService.running
    readonly property int remainingSeconds: Services.FocusTimerService.remainingSeconds
    readonly property real timerProgress: Services.FocusTimerService.progress

    property string timeString: ""
    property string dateString: ""
    property bool showColon: true
    property bool timerControlsOpen: false

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
        Services.FocusTimerService.start(minutes);
        root.timerControlsOpen = false;
        customTimerInput.text = "";
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
                    NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing }
                }

                Column {
                    id: clockInfoColumn
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: ThemeModule.Theme.spacingTiny

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: ThemeModule.Theme.spacingMicro

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
                            Behavior on opacity { NumberAnimation { duration: ThemeModule.Theme.animDurationFast } }
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
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: Services.WeatherService.enabled
                            && Services.WeatherService.currentWeatherStr !== "Loading..."
                            && Services.WeatherService.currentWeatherStr !== ""

                        height: 28
                        width: weatherRow.implicitWidth + ThemeModule.Theme.spacingXL
                        radius: height / 2
                        color: weatherMouse.containsMouse
                            ? ThemeModule.Theme.cardHover
                            : ThemeModule.Theme.controlFill
                        border.width: ThemeModule.Theme.borderWidth
                        border.color: weatherMouse.containsMouse
                            ? ThemeModule.Theme.accent
                            : ThemeModule.Theme.controlBorder

                        Accessible.role: Accessible.Button
                        Accessible.name: "Refresh weather"
                        Accessible.description: Services.WeatherService.currentWeatherStr
                        Accessible.onPressAction: Services.WeatherService.fetchWeather()

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
                iconName: "timer"
                iconSize: ThemeModule.Theme.iconSizeMedium
                iconColor: root.timerRunning || root.timerControlsOpen
                    ? root.timerAccentColor()
                    : ThemeModule.Theme.subtext
                hoverColor: ThemeModule.Theme.alpha(ThemeModule.Theme.accent,
                    root.timerRunning ? ThemeModule.Theme.tintStrong : ThemeModule.Theme.tintSubtle)
                tooltipText: root.timerRunning ? "Timer controls" : "Start timer"
                onClicked: root.timerControlsOpen = !root.timerControlsOpen

                Rectangle {
                    width: 5
                    height: 5
                    radius: width / 2
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

            Behavior on height { NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing } }
            Behavior on opacity { NumberAnimation { duration: ThemeModule.Theme.animDurationFast } }

            Rectangle {
                width: Math.min(parent.width, 272)
                height: 42
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: ThemeModule.Theme.spacingTiny
                radius: ThemeModule.Theme.borderRadius
                color: dockMouse.containsMouse
                    ? ThemeModule.Theme.alpha(ThemeModule.Theme.overlay, ThemeModule.Theme.tintStrong)
                    : ThemeModule.Theme.controlFill
                border.width: ThemeModule.Theme.borderWidth
                border.color: ThemeModule.Theme.alpha(root.timerAccentColor(), ThemeModule.Theme.tintStrong)

                Accessible.role: Accessible.Button
                Accessible.name: "Edit running timer"
                Accessible.description: root.formatTimer(root.remainingSeconds) + " remaining"
                Accessible.onPressAction: root.timerControlsOpen = !root.timerControlsOpen

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
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: ThemeModule.Theme.spacingSmall
                        rightMargin: ThemeModule.Theme.spacingSmall
                        topMargin: ThemeModule.Theme.spacingSmall
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
                            ctx.strokeStyle = ThemeModule.Theme.alpha(ThemeModule.Theme.overlay, 0.38);
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            ctx.arc(11, 11, 8, 0, Math.PI * 2);
                            ctx.stroke();

                            if (root.timerProgress > 0) {
                                ctx.strokeStyle = accent;
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
                            font.pixelSize: ThemeModule.Theme.fontSizeEmphasis
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: ThemeModule.Theme.text
                        }

                        Text {
                            text: "Focus timer"
                            font.pixelSize: ThemeModule.Theme.fontSizeMicro
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.overlay
                        }
                    }

                    Rectangle {
                        id: addFiveButton
                        width: 34
                        height: ThemeModule.Theme.controlHeightSmall
                        radius: ThemeModule.Theme.borderRadius
                        anchors.verticalCenter: parent.verticalCenter
                        color: ThemeModule.Theme.alpha(root.timerAccentColor(),
                            addFiveMouse.containsMouse ? ThemeModule.Theme.tintStrong : ThemeModule.Theme.tintSubtle)
                        border.width: ThemeModule.Theme.borderWidth
                        border.color: ThemeModule.Theme.alpha(root.timerAccentColor(), ThemeModule.Theme.tintOutline)

                        Accessible.role: Accessible.Button
                        Accessible.name: "Add five minutes"
                        Accessible.onPressAction: Services.FocusTimerService.addMinutes(5)
                        Text {
                            anchors.centerIn: parent
                            text: "+5"
                            font.pixelSize: ThemeModule.Theme.fontSizeCaption
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: root.timerAccentColor()
                        }

                        MouseArea {
                            id: addFiveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.FocusTimerService.addMinutes(5)
                        }
                    }

                    Rectangle {
                        id: stopSmallButton
                        width: ThemeModule.Theme.controlHeightSmall
                        height: ThemeModule.Theme.controlHeightSmall
                        radius: ThemeModule.Theme.borderRadius
                        anchors.verticalCenter: parent.verticalCenter
                        color: stopSmallMouse.containsMouse
                            ? ThemeModule.Theme.alpha(ThemeModule.Theme.error, ThemeModule.Theme.tintStrong)
                            : "transparent"
                        border.width: ThemeModule.Theme.borderWidth
                        border.color: ThemeModule.Theme.alpha(ThemeModule.Theme.error, ThemeModule.Theme.tintOutline)

                        Accessible.role: Accessible.Button
                        Accessible.name: "Stop timer"
                        Accessible.onPressAction: Services.FocusTimerService.stop()
                        Components.AppIcon {
                            anchors.centerIn: parent
                            name: "close"
                            size: ThemeModule.Theme.iconSizeSmall
                            iconColor: ThemeModule.Theme.error
                        }

                        MouseArea {
                            id: stopSmallMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.FocusTimerService.stop()
                        }
                    }
                }

                onVisibleChanged: timerDockDial.requestPaint()
            }
        }

        Rectangle {
            width: parent.width
            visible: root.timerControlsOpen
            height: controlsContent.height + ThemeModule.Theme.spacingMedium * 2
            radius: ThemeModule.Theme.borderRadiusSmall
            color: ThemeModule.Theme.controlFill
            border.width: ThemeModule.Theme.borderWidth
            border.color: ThemeModule.Theme.controlBorder
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
                        spacing: ThemeModule.Theme.spacingMicro

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
                            font.pixelSize: ThemeModule.Theme.fontSizeCaption
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
                        onActivated: Services.FocusTimerService.stop()
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
                            height: ThemeModule.Theme.controlHeight
                            radius: ThemeModule.Theme.borderRadius
                            color: ThemeModule.Theme.alpha(presetColor,
                                (presetMouse.containsMouse ? ThemeModule.Theme.tintStrong : ThemeModule.Theme.tintSubtle)
                                    + (primary ? ThemeModule.Theme.tintSubtle : 0))
                            border.width: ThemeModule.Theme.borderWidth
                            border.color: ThemeModule.Theme.alpha(presetColor,
                                primary ? ThemeModule.Theme.tintOutlineStrong : ThemeModule.Theme.tintOutline)

                            Accessible.role: Accessible.Button
                            Accessible.name: (root.timerRunning ? "Add " : "Start ") + presetButton.modelData + " minutes"
                            Accessible.onPressAction: {
                                if (root.timerRunning) Services.FocusTimerService.addMinutes(presetButton.modelData);
                                else root.startTimer(presetButton.modelData);
                            }
                            Behavior on color { ColorAnimation { duration: ThemeModule.Theme.animDuration } }

                            Text {
                                anchors.centerIn: parent
                                text: (root.timerRunning ? "+" : "") + presetButton.modelData + "m"
                                font.pixelSize: ThemeModule.Theme.fontSizeSmall
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
                                    if (root.timerRunning) Services.FocusTimerService.addMinutes(presetButton.modelData);
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
                        height: ThemeModule.Theme.controlHeight
                        focusPolicy: Qt.ClickFocus
                        background: Rectangle {
                            radius: ThemeModule.Theme.borderRadiusSmall
                            color: ThemeModule.Theme.card
                            border.width: ThemeModule.Theme.borderWidth
                            border.color: customTimerInput.activeFocus
                                ? ThemeModule.Theme.accent
                                : ThemeModule.Theme.cardHover
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
                        iconSize: ThemeModule.Theme.iconSizeSmall
                        iconName: "media-play"
                        iconColor: ThemeModule.Theme.text
                        hoverColor: ThemeModule.Theme.alpha(ThemeModule.Theme.accent, ThemeModule.Theme.tintStrong)
                        tooltipText: root.timerRunning ? "Reset timer" : "Start timer"
                        onClicked: root.startCustomTimer()
                    }
                }
            }
        }
    }
}
