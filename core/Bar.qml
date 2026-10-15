pragma ComponentBehavior: Bound
// qmllint disable missing-type uncreatable-type unqualified unresolved-type
import QtQuick
import QtQuick.Templates as T
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import "../components" as Components
import "../components/Icons.js" as Icons
import "../services" as Services
import "../theme" as ThemeModule
import "WidgetRegistry.js" as WidgetRegistry

// An experimental bar along the top or bottom of one screen: the dashboard's mark and
// this screen's workspaces; the clock, with play/pause for the playing track and a running
// timer beside it; the tray and panel icons. Everything but the mark, workspaces, and
// play/pause opens one of the dashboard's own panels, loaded as the dashboard loads them,
// in a dropdown on the screen's side of the bar. Speaker and microphone keep their own
// panels here, however the dashboard combines them.
//
// The window covers the screen so dropdowns, menus, and labels can draw beside the
// bar, and takes input only on the bar until one of them opens.
PanelWindow {
    id: root

    required property var modelData
    property var config: null

    // [Bar] position, height, width (percent of the screen), margin (from the screen's
    // edge; 0 docks the bar there), gap (to the windows), and outline.
    readonly property var settings: root.config
        ? root.config.bar
        : ({ position: "top", height: 40, width: 100, margin: 0, gap: 0, outline: "edges" })
    readonly property bool atTop: root.settings.position !== "bottom"
    readonly property int margin: root.settings.margin
    readonly property bool docked: root.margin === 0
    readonly property bool fullWidth: strip.width >= root.width
    // Labels and menus open toward the screen's middle.
    readonly property string labelSide: root.atTop ? "below" : "above"
    readonly property int panelMargin: root.config ? Math.max(0, root.config.panelMargin) : 16
    readonly property int barHeight: root.settings.height
    // Buttons fill the bar, short of the controls' usual height.
    readonly property int itemSize: Math.min(ThemeModule.Theme.controlHeight, root.barHeight - ThemeModule.Theme.spacingMicro * 2)
    // As much space beside the end buttons as above and below them.
    readonly property int edgePadding: Math.max(ThemeModule.Theme.spacingTiny, (root.barHeight - root.itemSize) / 2)
    // A dropdown's panel is as wide as in the dashboard's content area, so it lays out
    // the same; the dropdown adds padding on the left and the scrollbar's inset on the right.
    readonly property int panelContentWidth: (root.config ? root.config.panelWidth : 420)
        - ThemeModule.Theme.sidebarWidth - ThemeModule.Theme.separatorThickness - ThemeModule.Theme.panelPadding * 3
    // The panel icons, left to right, in groups: tools, status, and Speshell itself.
    readonly property var panelGroups: [
        ["tools", "clipboardManager", "notes"],
        ["audioControl", "audioInputControl", "displayControl", "networkPanel", "bluetoothPanel",
            "batteryStatus", "notificationCenter"],
        ["settings", "powerMenu"]
    ]
    readonly property string screenName: root.modelData ? root.modelData.name : ""

    // The open dropdown's panel and the button it hangs from.
    property string dropdown: ""
    property Item dropdownButton: null
    property int openMenus: 0
    readonly property bool overlayOpen: root.dropdown !== "" || root.openMenus > 0
    readonly property bool dropdownOpen: root.dropdown !== ""

    onDropdownOpenChanged: Services.DashboardService.openDropdowns += root.dropdownOpen ? 1 : -1
    Component.onDestruction: if (root.dropdownOpen) Services.DashboardService.openDropdowns -= 1

    // `pointer`: the MouseArea clicked, or null from the keyboard.
    function toggleDropdown(panelName, button, pointer) {
        if (root.dropdownButton === button) {
            root.closeDropdown();
            return;
        }
        Services.EffectsService.picked(button, pointer || null);
        root.dropdownButton = button;
        root.dropdown = panelName;
    }

    function step(panelName, direction) {
        if (panelName === "audioControl")
            Services.AudioService.stepOutputVolume(direction);
        else if (panelName === "audioInputControl")
            Services.AudioService.stepInputVolume(direction);
        else if (panelName === "displayControl")
            Services.BrightnessService.stepPercent(direction);
    }

    function cycleDevice(panelName) {
        if (panelName === "audioControl")
            Services.AudioService.cycleOutputDevice();
        else if (panelName === "audioInputControl")
            Services.AudioService.cycleInputDevice();
    }

    function formatTimer(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor(seconds % 3600 / 60);
        const rest = seconds % 60;
        return (hours > 0 ? hours + ":" + (minutes < 10 ? "0" : "") : "") + minutes + ":" + (rest < 10 ? "0" : "") + rest;
    }

    function statusIcon(panelName) {
        if (panelName === "audioControl") {
            if (Services.AudioService.outputMuted)
                return "audio-output-muted";
            return Services.AudioService.outputVolumePercent <= 35 ? "audio-output-low" : "audio-output-high";
        }
        if (panelName === "audioInputControl")
            return Services.AudioService.inputMuted ? "audio-input-muted" : "audio-input";
        if (panelName === "displayControl")
            return Services.BrightnessService.available ? "brightness" : "display";
        if (panelName === "networkPanel") {
            const network = Services.NetworkService;
            if (network.wiredDevice !== null)
                return "network-wired";
            return network.connectedWifi !== null
                ? network.signalIcon(network.signalPercent(network.connectedWifi.signalStrength))
                : "wifi-off";
        }
        if (panelName === "bluetoothPanel")
            return Services.BluetoothService.enabled ? "bluetooth" : "bluetooth-off";
        if (panelName === "batteryStatus") {
            const battery = UPower.displayDevice;
            if (!battery || !battery.ready)
                return "battery";
            return Icons.batteryFor(battery.percentage * 100, battery.state === UPowerDeviceState.Charging
                || battery.state === UPowerDeviceState.PendingCharge);
        }
        if (panelName === "notificationCenter")
            return Services.NotificationService.dndEnabled ? "bell-off" : "bell";
        if (panelName === "tools")
            return Services.ToolsService.statusIcon;
        return WidgetRegistry.icon(panelName);
    }

    function closeDropdown() {
        root.dropdown = "";
        root.dropdownButton = null;
    }

    screen: root.modelData
    anchors {
        top: root.atTop
        bottom: !root.atTop
        left: true
        right: true
    }
    implicitHeight: root.modelData ? root.modelData.height : 0
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: root.margin + root.barHeight + root.settings.gap
    mask: Region { item: root.overlayOpen ? content : strip }

    WlrLayershell.namespace: "speshell-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.dropdown !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // The dashboard covers this side of the screen; its panels belong to it then.
    Connections {
        target: Services.DashboardService

        function onWorkspaceVisibleChanged() {
            if (Services.DashboardService.workspaceVisible)
                root.closeDropdown();
        }

        function onDismissRequested() { root.closeDropdown(); }
    }

    Item {
        id: content
        anchors.fill: parent

        // Closes the dropdown or menu on a click anywhere outside it.
        MouseArea {
            anchors.fill: parent
            enabled: root.dropdown !== ""
            onPressed: root.closeDropdown()
        }

        Item {
            id: strip

            // The clock and timer stay centered unless a side crowds them; the track's
            // controls sit before the clock. Short of room, the bar grows wider than its
            // setting rather than overlap or drop anything.
            readonly property real gap: ThemeModule.Theme.spacingMedium
            readonly property real middleStart: leftRow.x + leftRow.width + strip.gap
            readonly property real middleEnd: rightRow.x - strip.gap
            readonly property real timerWidth: timerButton.visible ? ThemeModule.Theme.spacingTiny + timerButton.width : 0
            readonly property real mediaWidth: mediaControls.player !== null ? mediaControls.width + ThemeModule.Theme.spacingTiny : 0
            readonly property real requiredWidth: root.edgePadding * 2 + leftRow.width + rightRow.width
                + strip.gap * 2 + strip.mediaWidth + clockButton.width + strip.timerWidth

            x: Math.round((root.width - width) / 2)
            y: root.atTop ? root.margin : root.height - root.margin - root.barHeight
            width: Math.min(root.width, Math.max(Math.round(root.width * root.settings.width / 100),
                Math.ceil(strip.requiredWidth)))
            height: root.barHeight

            // Square, like the windows around it. Framed on every side that doesn't touch the
            // screen's edge, where the frame runs off screen; with the full outline, framed
            // there too, moved in by half the frame's stroke so it shows whole.
            Components.Surface {
                readonly property int screenEdgeMargin: root.settings.outline === "full" ? 1 : -2

                anchors.fill: parent
                anchors.topMargin: root.docked && root.atTop ? screenEdgeMargin : 0
                anchors.bottomMargin: root.docked && !root.atTop ? screenEdgeMargin : 0
                anchors.leftMargin: root.fullWidth ? screenEdgeMargin : 0
                anchors.rightMargin: root.fullWidth ? screenEdgeMargin : 0
                backdrop: true
                backdropHeight: 1050
            }

            // ── Dashboard mark and this screen's workspaces ──
            Row {
                id: leftRow
                anchors.left: parent.left
                anchors.leftMargin: root.edgePadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: ThemeModule.Theme.spacingTiny

                Item {
                    id: markButton

                    property bool pointerInside: false

                    width: root.itemSize
                    height: root.itemSize

                    Accessible.role: Accessible.Button
                    Accessible.name: "Dashboard"
                    Accessible.onPressAction: Services.DashboardService.toggleWorkspace()

                    Rectangle {
                        anchors.fill: parent
                        radius: ThemeModule.Theme.borderRadiusSmall
                        color: Services.DashboardService.workspaceVisible
                            ? ThemeModule.Theme.selectedFill
                            : (markButton.pointerInside ? ThemeModule.Theme.cardHover : "transparent")
                    }

                    // Drawn on a 29 px grid; crisp at that size, scaled down in short bars.
                    Components.SpeshellMark {
                        anchors.centerIn: parent
                        size: Math.min(29, root.itemSize - ThemeModule.Theme.spacingTiny)
                    }

                    Components.HoverLabel {
                        visible: markButton.pointerInside
                        text: "Dashboard"
                        placement: root.labelSide
                    }

                    MouseArea {
                        id: markMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: markButton.pointerInside = true
                        onExited: markButton.pointerInside = false
                        onCanceled: markButton.pointerInside = false
                        onClicked: {
                            Services.EffectsService.picked(markButton, markMouse);
                            root.closeDropdown();
                            Services.DashboardService.toggleWorkspace();
                        }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: ThemeModule.Theme.separatorThickness
                    height: Math.min(ThemeModule.Theme.controlHeightSmall, root.itemSize)
                    color: ThemeModule.Theme.separator
                }

                Repeater {
                    model: Services.WorkspaceService.all.filter(function(ws) {
                        return ws.monitor === root.screenName;
                    })

                    delegate: Rectangle {
                        id: workspace

                        required property var modelData
                        property bool pointerInside: false

                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(root.itemSize, nameText.implicitWidth + ThemeModule.Theme.spacingMedium * 2)
                        height: Math.min(ThemeModule.Theme.controlHeightSmall + ThemeModule.Theme.spacingTiny, root.itemSize)
                        radius: ThemeModule.Theme.borderRadiusSmall
                        color: workspace.modelData.active
                            ? ThemeModule.Theme.selectedFill
                            : (workspace.pointerInside ? ThemeModule.Theme.cardHover : "transparent")
                        border.width: workspace.modelData.active ? ThemeModule.Theme.borderWidth : 0
                        border.color: ThemeModule.Theme.selectedBorder

                        Accessible.role: Accessible.Button
                        Accessible.name: "Workspace " + workspace.modelData.name
                        Accessible.onPressAction: Services.WorkspaceService.focusWorkspace(workspace.modelData.id)

                        Text {
                            id: nameText
                            anchors.centerIn: parent
                            text: workspace.modelData.name
                            textFormat: Text.PlainText
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            font.weight: workspace.modelData.active ? Font.DemiBold : Font.Normal
                            color: workspace.modelData.active
                                ? ThemeModule.Theme.accent
                                : (workspace.modelData.apps.length > 0 ? ThemeModule.Theme.text : ThemeModule.Theme.subtext)
                        }

                        Components.HoverLabel {
                            visible: workspace.pointerInside && workspace.modelData.title !== ""
                            text: workspace.modelData.title
                            placement: root.labelSide
                        }

                        MouseArea {
                            id: workspaceMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: workspace.pointerInside = true
                            onExited: workspace.pointerInside = false
                            onCanceled: workspace.pointerInside = false
                            onClicked: {
                                if (!workspace.modelData.active)
                                    Services.EffectsService.picked(workspace, workspaceMouse);
                                Services.WorkspaceService.focusWorkspace(workspace.modelData.id);
                            }
                        }
                    }
                }
            }

            // ── Clock, opening the calendar, between the playing track and a running timer ──
            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            TextButton {
                id: clockButton
                bar: root
                x: Math.max(strip.middleStart + strip.mediaWidth, Math.min(strip.middleEnd - strip.timerWidth - width,
                    Math.round((strip.width - width) / 2)))
                anchors.verticalCenter: parent.verticalCenter
                panelName: "calendar"
                horizontalPadding: ThemeModule.Theme.spacingLarge
                text: Qt.formatDateTime(clock.date, "ddd d MMM") + "   " + Qt.formatDateTime(clock.date, "HH:mm")
                fontSize: ThemeModule.Theme.fontSizeNormal
                fontWeight: Font.DemiBold
            }

            // Play/pause in place; the cover opens the full player, its track named on hover.
            Row {
                id: mediaControls

                readonly property var player: Services.MediaService.player

                anchors.right: clockButton.left
                anchors.rightMargin: ThemeModule.Theme.spacingTiny
                anchors.verticalCenter: parent.verticalCenter
                visible: player !== null
                spacing: ThemeModule.Theme.spacingMicro

                BarButton {
                    id: playButton
                    bar: root
                    label: Services.MediaService.playing ? "Pause" : "Play"
                    onClicked: if (mediaControls.player) mediaControls.player.togglePlaying()

                    Components.AppIcon {
                        anchors.centerIn: parent
                        // The play triangle's weight sits left of its box.
                        anchors.horizontalCenterOffset: Services.MediaService.playing ? 0 : 1
                        name: Services.MediaService.playing ? "media-pause" : "media-play"
                        size: ThemeModule.Theme.iconSizeMedium
                        iconColor: playButton.pointerInside ? ThemeModule.Theme.text : ThemeModule.Theme.subtextBright
                    }
                }

                BarButton {
                    id: mediaButton

                    readonly property int coverSize: root.itemSize - ThemeModule.Theme.spacingSmall

                    bar: root
                    open: root.dropdownButton === mediaButton
                    label: mediaControls.player
                        ? [mediaControls.player.trackTitle || "Unknown track", mediaControls.player.trackArtist].filter(Boolean).join(" · ")
                        : ""
                    onClicked: function(pointer) { root.toggleDropdown("nowPlaying", mediaButton, pointer); }

                    Rectangle {
                        anchors.centerIn: parent
                        width: mediaButton.coverSize
                        height: mediaButton.coverSize
                        radius: ThemeModule.Theme.borderRadiusSmall
                        color: cover.status === Image.Ready ? "transparent" : ThemeModule.Theme.controlFill
                        // Dimmed while paused.
                        opacity: Services.MediaService.playing || mediaButton.pointerInside || mediaButton.open
                            ? 1
                            : ThemeModule.Theme.disabledOpacity
                        clip: true

                        Image {
                            id: cover
                            anchors.fill: parent
                            source: mediaControls.player && mediaControls.player.trackArtUrl ? mediaControls.player.trackArtUrl : ""
                            sourceSize.width: mediaButton.coverSize * 2
                            sourceSize.height: mediaButton.coverSize * 2
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: cover.status === Image.Ready
                        }

                        Components.AppIcon {
                            anchors.centerIn: parent
                            visible: cover.status !== Image.Ready
                            name: "media"
                            size: ThemeModule.Theme.iconSizeSmall
                            iconColor: mediaButton.open ? ThemeModule.Theme.accent : ThemeModule.Theme.subtextBright
                        }
                    }
                }
            }

            TextButton {
                id: timerButton
                bar: root
                anchors.left: clockButton.right
                anchors.leftMargin: ThemeModule.Theme.spacingTiny
                anchors.verticalCenter: parent.verticalCenter
                visible: Services.FocusTimerService.running
                panelName: "clock"
                iconName: "timer"
                iconColor: ThemeModule.Theme.accent
                text: root.formatTimer(Services.FocusTimerService.remainingSeconds)
                hoverText: "Timer"
            }

            // ── Tray and panel icons ──
            Row {
                id: rightRow
                anchors.right: parent.right
                anchors.rightMargin: root.edgePadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: ThemeModule.Theme.spacingTiny

                // Other apps' icons, in a well of their own, as on the dashboard's rail.
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: trayRepeater.count > 0
                    width: trayRow.implicitWidth + ThemeModule.Theme.spacingTiny * 2
                    height: root.itemSize
                    radius: ThemeModule.Theme.borderRadius
                    color: ThemeModule.Theme.controlFill
                    border.width: ThemeModule.Theme.borderWidth
                    border.color: ThemeModule.Theme.controlBorder

                    Row {
                        id: trayRow
                        anchors.centerIn: parent

                        Repeater {
                            id: trayRepeater
                            model: SystemTray.items

                            delegate: Components.TrayItem {
                                width: root.itemSize - ThemeModule.Theme.spacingTiny
                                height: root.itemSize - ThemeModule.Theme.spacingTiny
                                menuX: 0
                                menuY: height + ThemeModule.Theme.spacingMedium
                                menuAbove: !root.atTop
                                labelPlacement: root.labelSide + "-end"
                                onMenuOpenChanged: root.openMenus = Math.max(0, root.openMenus + (menuOpen ? 1 : -1))
                                Component.onDestruction: if (menuOpen) root.openMenus = Math.max(0, root.openMenus - 1)
                            }
                        }
                    }
                }

                Repeater {
                    model: root.panelGroups

                    delegate: Row {
                        id: group

                        required property var modelData
                        required property int index

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: ThemeModule.Theme.spacingTiny

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: group.index > 0
                            width: ThemeModule.Theme.separatorThickness
                            height: Math.min(ThemeModule.Theme.controlHeightSmall, root.itemSize)
                            color: ThemeModule.Theme.separator
                        }

                        Repeater {
                            model: group.modelData

                            delegate: BarButton {
                                id: button

                                required property string modelData

                                bar: root
                                visible: Services.DashboardService.isPanelSupported(button.modelData)
                                open: root.dropdownButton === button
                                label: Services.DashboardService.statusText(button.modelData)
                                labelPlacement: root.labelSide + "-end"
                                onClicked: function(pointer) { root.toggleDropdown(button.modelData, button, pointer); }
                                onWheeled: function(delta) { root.step(button.modelData, delta); }
                                onRightClicked: root.cycleDevice(button.modelData)

                                Components.AppIcon {
                                    anchors.centerIn: parent
                                    name: root.statusIcon(button.modelData)
                                    size: ThemeModule.Theme.iconSizeMedium
                                    iconColor: button.open
                                        ? ThemeModule.Theme.accent
                                        : (button.modelData === "tools" && Services.ToolsService.statusTone !== ""
                                            ? ThemeModule.Theme.toneColor(Services.ToolsService.statusTone)
                                            : (button.pointerInside ? ThemeModule.Theme.text : ThemeModule.Theme.subtextBright))
                                }

                                // Unread notifications.
                                Rectangle {
                                    visible: button.modelData === "notificationCenter"
                                        && Services.NotificationService.notificationHistory.length > 0
                                    x: parent.width - width - ThemeModule.Theme.spacingTiny
                                    y: ThemeModule.Theme.spacingTiny
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: ThemeModule.Theme.accent
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Dropdown: one dashboard panel beside the button that opened it ──
        Item {
            id: dropdownCard

            readonly property real anchorX: root.dropdownButton
                ? root.dropdownButton.mapToItem(content, root.dropdownButton.width / 2, 0).x
                : 0
            readonly property real maxHeight: (root.atTop ? root.height - strip.y - strip.height : strip.y)
                - ThemeModule.Theme.spacingSmall - root.panelMargin

            visible: root.dropdown !== ""
            x: Math.max(root.panelMargin, Math.min(root.width - root.panelMargin - width, anchorX - width / 2))
            y: root.atTop
                ? strip.y + strip.height + ThemeModule.Theme.spacingSmall
                : strip.y - ThemeModule.Theme.spacingSmall - height
            width: root.panelContentWidth + ThemeModule.Theme.panelPadding * 3
            height: Math.min(maxHeight, panelLoader.height + ThemeModule.Theme.panelPadding * 2)
            opacity: 0

            onVisibleChanged: if (visible) entrance.restart()

            ParallelAnimation {
                id: entrance
                NumberAnimation { target: dropdownCard; property: "opacity"; from: 0; to: 1; duration: ThemeModule.Theme.animDurationFast }
                NumberAnimation {
                    target: dropdownSlide; property: "y"
                    from: root.atTop ? -ThemeModule.Theme.spacingSmall : ThemeModule.Theme.spacingSmall; to: 0
                    duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing
                }
            }

            transform: Translate { id: dropdownSlide }

            // Swallows clicks so they don't reach the closing area behind.
            MouseArea {
                anchors.fill: parent
            }

            Components.Surface {
                anchors.fill: parent
                backdrop: true
                backdropHeight: 1050
                cutTopLeft: !root.atTop
                cutTopRight: !root.atTop
                cutBottomLeft: root.atTop
                cutBottomRight: root.atTop
            }

            FocusScope {
                anchors.fill: parent
                anchors.leftMargin: ThemeModule.Theme.panelPadding
                anchors.topMargin: ThemeModule.Theme.panelPadding
                anchors.bottomMargin: ThemeModule.Theme.panelPadding
                focus: root.dropdown !== ""

                Keys.onEscapePressed: root.closeDropdown()

                Flickable {
                    id: dropdownFlickable

                    readonly property bool needsVerticalScroll: contentHeight > height + 1

                    anchors.fill: parent
                    contentHeight: panelLoader.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 3000

                    T.ScrollBar.vertical: Components.StyledScrollBar {
                        policy: dropdownFlickable.needsVerticalScroll ? T.ScrollBar.AsNeeded : T.ScrollBar.AlwaysOff
                    }

                    WidgetLoader {
                        id: panelLoader
                        width: root.panelContentWidth
                        name: root.dropdown
                        config: root.config
                        audioSeparate: true
                        presented: root.dropdown !== "" && root.visible
                    }
                }
            }
        }

        // The theme effects' interactions over the bar and its dropdown.
        InteractionsLayer {
            z: 200
            anchors.fill: parent
            host: content
            presented: root.visible
        }
    }

    // A square bar button, its content given by the user: hover and open fills, a label
    // while the pointer is over it, a click, a right click, and the wheel.
    component BarButton: Item {
        id: barButton

        property var bar: null
        property bool open: false
        property string label: ""
        property string labelPlacement: barButton.bar ? barButton.bar.labelSide : "below"
        property bool pointerInside: false

        // `pointer`: the MouseArea clicked, or null from the keyboard.
        signal clicked(Item pointer)
        signal wheeled(real delta)
        signal rightClicked()

        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        width: barButton.bar ? barButton.bar.itemSize : ThemeModule.Theme.controlHeight
        height: barButton.width

        Accessible.role: Accessible.Button
        Accessible.name: barButton.label
        Accessible.onPressAction: barButton.clicked(null)

        Rectangle {
            anchors.fill: parent
            radius: ThemeModule.Theme.borderRadiusSmall
            color: barButton.open
                ? ThemeModule.Theme.selectedFill
                : (barButton.pointerInside ? ThemeModule.Theme.cardHover : "transparent")
            border.width: barButton.open ? ThemeModule.Theme.borderWidth : 0
            border.color: ThemeModule.Theme.selectedBorder
        }

        Components.HoverLabel {
            visible: barButton.pointerInside && !barButton.open && barButton.label !== ""
            text: barButton.label
            placement: barButton.labelPlacement
        }

        MouseArea {
            id: barMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onEntered: barButton.pointerInside = true
            onExited: barButton.pointerInside = false
            onCanceled: barButton.pointerInside = false
            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton)
                    barButton.rightClicked();
                else
                    barButton.clicked(barMouse);
            }
            onWheel: function(wheel) { barButton.wheeled(wheel.angleDelta.y); }
        }
    }

    // A labelled bar button that opens a panel: the clock, a running timer.
    component TextButton: Rectangle {
        id: textButton

        property var bar: null
        property string panelName: ""
        property string iconName: ""
        property color iconColor: ThemeModule.Theme.subtextBright
        property alias text: label.text
        property int fontSize: ThemeModule.Theme.fontSizeSmall
        property int fontWeight: Font.Normal
        property int horizontalPadding: ThemeModule.Theme.spacingMedium
        property string hoverText: ""
        readonly property bool open: textButton.bar !== null && textButton.bar.dropdownButton === textButton
        property bool pointerInside: false

        width: buttonRow.implicitWidth + textButton.horizontalPadding * 2
        height: textButton.bar ? textButton.bar.itemSize : ThemeModule.Theme.controlHeight
        radius: ThemeModule.Theme.borderRadiusSmall
        color: textButton.open
            ? ThemeModule.Theme.selectedFill
            : (textButton.pointerInside ? ThemeModule.Theme.cardHover : "transparent")
        border.width: textButton.open ? ThemeModule.Theme.borderWidth : 0
        border.color: ThemeModule.Theme.selectedBorder

        Accessible.role: Accessible.Button
        Accessible.name: textButton.text
        Accessible.onPressAction: textButton.bar.toggleDropdown(textButton.panelName, textButton)

        Row {
            id: buttonRow
            anchors.centerIn: parent
            spacing: ThemeModule.Theme.spacingSmall

            Components.AppIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: textButton.iconName !== ""
                name: textButton.iconName
                size: ThemeModule.Theme.iconSizeSmall
                iconColor: textButton.open ? ThemeModule.Theme.accent : textButton.iconColor
            }

            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.PlainText
                font.pixelSize: textButton.fontSize
                font.family: ThemeModule.Theme.fontFamily
                font.weight: textButton.fontWeight
                color: textButton.open ? ThemeModule.Theme.accent : ThemeModule.Theme.text
            }
        }

        Components.HoverLabel {
            visible: textButton.pointerInside && !textButton.open && textButton.hoverText !== ""
            text: textButton.hoverText
            placement: textButton.bar ? textButton.bar.labelSide : "below"
        }

        MouseArea {
            id: textMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: textButton.pointerInside = true
            onExited: textButton.pointerInside = false
            onCanceled: textButton.pointerInside = false
            onClicked: textButton.bar.toggleDropdown(textButton.panelName, textButton, textMouse)
        }
    }
}
