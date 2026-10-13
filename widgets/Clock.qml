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
    // Weather and a running timer share one line under the date. It keeps its
    // height while weather loads, so the panel doesn't shift when it arrives.
    readonly property bool statusLineShown: Services.WeatherService.enabled || root.timerRunning

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
        spacing: ThemeModule.Theme.spacingSmall

        Item {
            width: parent.width
            height: clockInfoColumn.implicitHeight

            Column {
                id: clockInfoColumn
                anchors.horizontalCenter: parent.horizontalCenter
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

                Item {
                    width: statusRow.width
                    height: root.statusLineShown ? ThemeModule.Theme.controlHeightSmall + ThemeModule.Theme.spacingTiny : 0
                    anchors.horizontalCenter: parent.horizontalCenter

                    Row {
                        id: statusRow
                        anchors.bottom: parent.bottom
                        spacing: ThemeModule.Theme.spacingSmall

                        StatusChip {
                            visible: Services.WeatherService.status === "ready"
                                || Services.WeatherService.status === "offline"
                            iconName: Services.WeatherService.status === "ready"
                                ? Services.WeatherService.iconName
                                : "weather-cloudy"
                            text: Services.WeatherService.status === "ready"
                                ? Services.WeatherService.temperature
                                : "Offline"
                            muted: Services.WeatherService.status !== "ready"
                            tooltipText: (Services.WeatherService.status === "ready"
                                ? Services.WeatherService.condition
                                : "Weather unavailable") + " · click to refresh"
                            onActivated: Services.WeatherService.fetchWeather()
                        }

                        StatusChip {
                            visible: root.timerRunning
                            text: root.formatTimer(root.remainingSeconds)
                            accented: true
                            selected: root.timerControlsOpen
                            tooltipText: "Focus timer"
                            onActivated: root.timerControlsOpen = !root.timerControlsOpen

                            Canvas {
                                id: timerDial
                                width: ThemeModule.Theme.iconSizeTiny
                                height: ThemeModule.Theme.iconSizeTiny
                                onPaint: {
                                    var ctx = getContext("2d");
                                    var center = width / 2;
                                    var radius = center - 1.5;
                                    ctx.reset();
                                    ctx.lineWidth = 2;
                                    ctx.strokeStyle = ThemeModule.Theme.alpha(ThemeModule.Theme.accent, ThemeModule.Theme.tintOutline);
                                    ctx.beginPath();
                                    ctx.arc(center, center, radius, 0, Math.PI * 2);
                                    ctx.stroke();
                                    ctx.strokeStyle = ThemeModule.Theme.accent;
                                    ctx.beginPath();
                                    ctx.arc(center, center, radius, -Math.PI / 2,
                                        -Math.PI / 2 + root.timerProgress * Math.PI * 2, false);
                                    ctx.stroke();
                                }
                                Component.onCompleted: requestPaint()

                                Connections {
                                    target: root
                                    function onTimerProgressChanged() {
                                        timerDial.requestPaint();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Components.IconButton {
                anchors.right: parent.right
                anchors.top: parent.top
                iconName: "timer"
                iconSize: ThemeModule.Theme.iconSizeMedium
                iconColor: root.timerRunning || root.timerControlsOpen
                    ? ThemeModule.Theme.accent
                    : ThemeModule.Theme.subtext
                hoverColor: ThemeModule.Theme.alpha(ThemeModule.Theme.accent, ThemeModule.Theme.tintSubtle)
                tooltipText: "Focus timer"
                onClicked: root.timerControlsOpen = !root.timerControlsOpen
            }
        }

        // One row of timer actions: presets and a custom length when idle, extra
        // time and Stop while running. The remaining time lives in the chip above.
        Rectangle {
            width: parent.width
            visible: root.timerControlsOpen
            height: ThemeModule.Theme.controlHeight + ThemeModule.Theme.spacingSmall * 2
            radius: ThemeModule.Theme.borderRadius
            color: ThemeModule.Theme.controlFill
            border.width: ThemeModule.Theme.borderWidth
            border.color: ThemeModule.Theme.controlBorder

            Row {
                id: timerActions
                anchors.left: parent.left
                anchors.leftMargin: ThemeModule.Theme.spacingSmall
                anchors.verticalCenter: parent.verticalCenter
                spacing: ThemeModule.Theme.spacingTiny

                Repeater {
                    model: root.timerRunning ? [1, 5, 10] : [5, 10, 25, 45]
                    delegate: Components.InlineActionChip {
                        required property int modelData
                        width: 46
                        height: ThemeModule.Theme.controlHeightSmall
                        text: (root.timerRunning ? "+" : "") + modelData + "m"
                        tone: "accent"
                        armed: !root.timerRunning && modelData === 25
                        Accessible.name: (root.timerRunning ? "Add " : "Start ") + modelData + " minutes"
                        onActivated: {
                            if (root.timerRunning)
                                Services.FocusTimerService.addMinutes(modelData);
                            else
                                root.startTimer(modelData);
                        }
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: ThemeModule.Theme.spacingSmall
                anchors.verticalCenter: parent.verticalCenter
                spacing: ThemeModule.Theme.spacingTiny

                TextField {
                    id: customTimerInput
                    visible: !root.timerRunning
                    width: 76
                    height: ThemeModule.Theme.controlHeightSmall
                    anchors.verticalCenter: parent.verticalCenter
                    focusPolicy: Qt.ClickFocus
                    background: Rectangle {
                        radius: ThemeModule.Theme.borderRadiusSmall
                        color: ThemeModule.Theme.card
                        border.width: ThemeModule.Theme.borderWidth
                        border.color: customTimerInput.activeFocus
                            ? ThemeModule.Theme.accent
                            : ThemeModule.Theme.controlBorder
                    }
                    leftPadding: ThemeModule.Theme.spacingSmall
                    rightPadding: ThemeModule.Theme.spacingSmall
                    topPadding: 0
                    bottomPadding: 0
                    verticalAlignment: TextInput.AlignVCenter
                    color: ThemeModule.Theme.text
                    placeholderTextColor: ThemeModule.Theme.subtext
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    placeholderText: "Minutes"
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator { bottom: 1; top: 720 }
                    onAccepted: root.startCustomTimer()
                }

                Components.IconButton {
                    visible: !root.timerRunning
                    size: ThemeModule.Theme.controlHeightSmall
                    anchors.verticalCenter: parent.verticalCenter
                    iconSize: ThemeModule.Theme.iconSizeSmall
                    iconName: "media-play"
                    iconColor: customTimerInput.acceptableInput ? ThemeModule.Theme.accent : ThemeModule.Theme.subtext
                    hoverColor: ThemeModule.Theme.alpha(ThemeModule.Theme.accent, ThemeModule.Theme.tintSubtle)
                    tooltipText: "Start timer"
                    onClicked: root.startCustomTimer()
                }

                Components.InlineActionChip {
                    visible: root.timerRunning
                    anchors.verticalCenter: parent.verticalCenter
                    height: ThemeModule.Theme.controlHeightSmall
                    text: "Stop"
                    iconName: "close"
                    tone: "error"
                    onActivated: {
                        Services.FocusTimerService.stop();
                        root.timerControlsOpen = false;
                    }
                }
            }
        }
    }

    // A small pill in the status line under the date.
    component StatusChip: Rectangle {
        id: chip

        default property alias leading: leadingSlot.data
        property string iconName: ""
        property string text: ""
        property string tooltipText: ""
        property bool muted: false
        property bool accented: false
        property bool selected: false
        readonly property color tint: chip.accented ? ThemeModule.Theme.accent : ThemeModule.Theme.text

        signal activated()

        height: ThemeModule.Theme.controlHeightSmall
        width: chipRow.implicitWidth + ThemeModule.Theme.spacingMedium * 2
        radius: height / 2
        color: chipMouse.containsMouse || chip.selected
            ? ThemeModule.Theme.alpha(chip.accented ? ThemeModule.Theme.accent : ThemeModule.Theme.overlay, ThemeModule.Theme.tintStrong)
            : ThemeModule.Theme.controlFill
        border.width: ThemeModule.Theme.borderWidth
        border.color: chip.accented
            ? ThemeModule.Theme.alpha(ThemeModule.Theme.accent, ThemeModule.Theme.tintOutline)
            : ThemeModule.Theme.controlBorder

        Accessible.role: Accessible.Button
        Accessible.name: chip.tooltipText
        Accessible.description: chip.text
        Accessible.onPressAction: chip.activated()

        Behavior on color { ColorAnimation { duration: ThemeModule.Theme.animDuration } }

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: ThemeModule.Theme.spacingTiny + ThemeModule.Theme.spacingMicro

            Item {
                id: leadingSlot
                width: childrenRect.width
                height: childrenRect.height
                visible: children.length > 0
                anchors.verticalCenter: parent.verticalCenter
            }

            Components.AppIcon {
                visible: chip.iconName !== ""
                name: chip.iconName
                size: ThemeModule.Theme.iconSizeSmall
                iconColor: chip.muted ? ThemeModule.Theme.subtext : chip.tint
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: chip.text
                font.pixelSize: ThemeModule.Theme.fontSizeSupporting
                font.family: ThemeModule.Theme.fontFamily
                font.bold: !chip.muted
                font.features: { "tnum": 1 }
                color: chip.muted ? ThemeModule.Theme.subtext : chip.tint
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.activated()
            ToolTip.visible: containsMouse && chip.tooltipText !== ""
            ToolTip.text: chip.tooltipText
            ToolTip.delay: 300
        }
    }
}
