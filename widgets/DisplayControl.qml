pragma ComponentBehavior: Bound
// qmllint disable signal-handler-parameters

import QtQuick
import QtQuick.Controls as Controls
import QtQml.Models
import "../components" as Components
import "../theme" as ThemeModule
import "../services" as Services

Components.Card {
    id: root
    title: "Displays"
    iconName: "display"
    visible: Services.FeatureSupport.supportsDisplayControl

    property bool presented: false
    readonly property bool busy: Services.DisplayService.displayEditingLocked
    readonly property var selectedMonitor: Services.DisplayService.monitorByName(
        Services.DisplayService.draftMonitors,
        Services.DisplayService.selectedName
    )
    readonly property bool selectedEnabled: root.selectedMonitor !== null && !root.selectedMonitor.disabled
    readonly property var selectedModeOptions: root.selectedEnabled
        ? Services.DisplayService.availableModesFor(root.selectedMonitor)
        : []
    readonly property bool canPositionSelected: root.selectedEnabled
        && Services.DisplayService.draftLayoutMode === "extend"
        && Services.DisplayService.firstOtherActiveDraftMonitor(Services.DisplayService.monitorName(root.selectedMonitor)) !== null
    readonly property bool canControlSelectedBrightness: root.selectedEnabled
        && Services.BrightnessService.available
        && root.isBrightnessDisplay(root.selectedMonitor)

    Component.onCompleted: {
        if (root.presented) {
            Services.DisplayService.refresh();
            root.requestBrightnessRefresh();
        }
    }

    onPresentedChanged: {
        if (root.presented) {
            Services.DisplayService.refresh();
            root.requestBrightnessRefresh();
        }
    }

    onSelectedMonitorChanged: root.requestBrightnessRefresh()
    onCanControlSelectedBrightnessChanged: root.requestBrightnessRefresh()

    function isBrightnessDisplay(monitor) {
        if (!monitor) {
            return false;
        }

        var name = Services.DisplayService.monitorName(monitor).toLowerCase();
        if (name.indexOf("edp") === 0 || name.indexOf("lvds") === 0 || name.indexOf("dsi") === 0) {
            return true;
        }

        return Services.DisplayService.draftActiveMonitors.length <= 1;
    }

    function modeText(monitor) {
        if (!monitor || monitor.disabled) {
            return "Off";
        }
        return Services.DisplayService.modeLabel(Services.DisplayService.monitorModeString(monitor));
    }

    function layoutLabel(mode) {
        if (mode === "mirror") {
            return "Mirror";
        }
        if (mode === "extend") {
            return "Extend";
        }
        return "Single";
    }

    function layoutTone(mode) {
        if (mode === "mirror") {
            return "info";
        }
        if (mode === "extend") {
            return "success";
        }
        return "neutral";
    }

    function statusText() {
        if (Services.DisplayService.errorText !== "") {
            return Services.DisplayService.errorText;
        }
        if (Services.DisplayService.reverting) {
            return "Restoring the previous display layout.";
        }
        if (Services.DisplayService.confirming) {
            return "Waiting for display confirmation.";
        }
        if (Services.DisplayService.applying) {
            return "Applying display changes.";
        }
        if (Services.DisplayService.loading) {
            return "Reading display state.";
        }
        if (Services.DisplayService.hasPending) {
            return Services.DisplayService.pendingSummary;
        }
        if (Services.DisplayService.monitors.length === 0) {
            return "No displays reported by Hyprland.";
        }

        return Services.DisplayService.draftActiveMonitors.length + " active / "
            + Services.DisplayService.draftMonitors.length + " detected";
    }

    function positionLabel() {
        if (!root.canPositionSelected) {
            return "Auto";
        }

        var selected = root.selectedMonitor;
        var anchor = Services.DisplayService.firstOtherActiveDraftMonitor(Services.DisplayService.monitorName(selected));
        if (!anchor) {
            return "Auto";
        }

        var dx = (Number(selected.x) || 0) - (Number(anchor.x) || 0);
        var dy = (Number(selected.y) || 0) - (Number(anchor.y) || 0);
        var anchorName = Services.DisplayService.monitorName(anchor);
        if (Math.abs(dx) >= Math.abs(dy)) {
            return (dx < 0 ? "Left of " : "Right of ") + anchorName;
        }
        return (dy < 0 ? "Above " : "Below ") + anchorName;
    }

    function requestBrightnessRefresh() {
        if (root.presented && root.canControlSelectedBrightness)
            Services.BrightnessService.refresh();
    }

    headerActions: Row {
        spacing: ThemeModule.Theme.spacingSmall

        Components.InlineActionChip {
            visible: Services.DisplayService.hasPending
            text: "Revert"
            iconName: "back"
            tone: "neutral"
            enabled: !Services.DisplayService.applying
            onActivated: Services.DisplayService.resetDraft()
        }

        Components.InlineActionChip {
            visible: Services.DisplayService.hasPending
            text: "Apply"
            iconName: "check"
            tone: "success"
            enabled: Services.DisplayService.hasPending && !root.busy
            onActivated: Services.DisplayService.applyDraft()
        }

        Components.InlineActionChip {
            visible: Services.DisplayService.rollbackRetryAvailable
            text: "Retry Revert"
            iconName: "back"
            tone: "warning"
            enabled: !Services.DisplayService.applying
            onActivated: Services.DisplayService.revertDisplayChanges()
        }

        Components.RefreshButton {
            active: root.busy
            enabled: !root.busy
            tooltipText: root.busy ? "Display refresh is busy" : "Refresh displays"
            onClicked: Services.DisplayService.refresh()
        }
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium

        Row {
            id: statusRow
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: Services.DisplayService.monitors.length > 0 || root.statusText() !== ""

            Components.StatusBadge {
                id: layoutBadge
                visible: Services.DisplayService.monitors.length > 0
                text: root.layoutLabel(Services.DisplayService.draftLayoutMode)
                tone: root.layoutTone(Services.DisplayService.draftLayoutMode)
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                width: Math.max(0, statusRow.width
                    - (layoutBadge.visible ? layoutBadge.width + statusRow.spacing : 0))
                text: root.statusText()
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: Services.DisplayService.errorText !== ""
                    ? ThemeModule.Theme.error
                    : (Services.DisplayService.hasPending ? ThemeModule.Theme.warning : ThemeModule.Theme.subtext)
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {

            width: parent.width
            visible: Services.DisplayService.confirming || Services.DisplayService.reverting
            implicitHeight: confirmationColumn.implicitHeight + ThemeModule.Theme.spacingMedium * 2
            radius: ThemeModule.Theme.borderRadiusSmall
            color: ThemeModule.Theme.alpha(ThemeModule.Theme.warning, ThemeModule.Theme.tintSubtle)
            border.width: ThemeModule.Theme.borderWidth
            border.color: ThemeModule.Theme.alpha(ThemeModule.Theme.warning, ThemeModule.Theme.tintOutline)

            Column {
                id: confirmationColumn

                x: ThemeModule.Theme.spacingMedium
                y: ThemeModule.Theme.spacingMedium
                width: parent.width - ThemeModule.Theme.spacingMedium * 2
                spacing: ThemeModule.Theme.spacingSmall

                Text {
                    width: parent.width
                    text: Services.DisplayService.reverting
                        ? "Restoring previous display settings…"
                        : "Keep these display settings?"
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    font.family: ThemeModule.Theme.fontFamily
                    font.bold: true
                    color: ThemeModule.Theme.text
                }

                Text {
                    width: parent.width
                    visible: Services.DisplayService.confirming
                    text: "Changes revert automatically in "
                        + Services.DisplayService.confirmationSecondsRemaining + " seconds."
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.subtext
                    wrapMode: Text.WordWrap
                }

                Row {
                    width: parent.width
                    spacing: ThemeModule.Theme.spacingSmall
                    visible: Services.DisplayService.confirming

                    Components.ActionButton {
                        width: (parent.width - parent.spacing) / 2
                        label: "Revert"
                        iconName: "back"
                        enabled: !Services.DisplayService.applying
                        onActivated: Services.DisplayService.revertDisplayChanges()
                    }

                    Components.ActionButton {
                        width: (parent.width - parent.spacing) / 2
                        label: "Keep Changes"
                        iconName: "check"
                        toneColor: ThemeModule.Theme.success
                        enabled: !Services.DisplayService.applying
                        onActivated: Services.DisplayService.keepDisplayChanges()
                    }
                }
            }
        }

        Rectangle {
            id: displayMap
            width: parent.width
            height: 148
            visible: Services.DisplayService.monitors.length > 0
            radius: ThemeModule.Theme.borderRadiusSmall
            color: ThemeModule.Theme.controlFill
            border.width: ThemeModule.Theme.borderWidth
            border.color: ThemeModule.Theme.controlBorder
            clip: true

            Text {
                anchors.centerIn: parent
                text: "No active displays"
                visible: Services.DisplayService.draftActiveMonitors.length === 0
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.overlay
            }

            Repeater {
                model: Services.DisplayService.draftActiveMonitors

                delegate: Rectangle {
                    id: displayTile

                    required property var modelData
                    readonly property var rect: Services.DisplayService.mapRect(
                        displayTile.modelData,
                        displayMap.width,
                        displayMap.height
                    )
                    readonly property bool selected: Services.DisplayService.monitorName(displayTile.modelData)
                        === Services.DisplayService.selectedName

                    x: rect.x
                    y: rect.y
                    width: Math.min(Math.max(34, rect.width), displayMap.width - 20)
                    height: Math.min(Math.max(24, rect.height), displayMap.height - 20)
                    radius: ThemeModule.Theme.borderRadius
                    z: selected ? 2 : 1
                    color: selected
                        ? ThemeModule.Theme.alpha(ThemeModule.Theme.accent, ThemeModule.Theme.tintStrong)
                        : ThemeModule.Theme.alpha(ThemeModule.Theme.surface2, 0.72)
                    border.width: ThemeModule.Theme.borderWidth
                    border.color: selected
                        ? ThemeModule.Theme.accent
                        : ThemeModule.Theme.alpha(ThemeModule.Theme.overlay, ThemeModule.Theme.tintOutline)

                    Accessible.role: Accessible.Button
                    Accessible.name: "Select " + Services.DisplayService.monitorName(displayTile.modelData)
                    Accessible.onPressAction: Services.DisplayService.setSelected(displayTile.modelData.name)

                    Column {
                        anchors.centerIn: parent
                        width: Math.max(0, parent.width - ThemeModule.Theme.spacingSmall)
                        spacing: ThemeModule.Theme.spacingMicro

                        Text {
                            width: parent.width
                            text: displayTile.modelData.name || "Display"
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.pixelSize: ThemeModule.Theme.fontSizeCaption
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: ThemeModule.Theme.text
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.DisplayService.setSelected(displayTile.modelData.name)
                    }

                    Behavior on x { NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing } }
                    Behavior on y { NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing } }
                    Behavior on width { NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing } }
                    Behavior on height { NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: ThemeModule.Theme.animEasing } }
                }
            }
        }

        Flow {
            id: displayPicker
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: Services.DisplayService.draftMonitors.length > 0

            Repeater {
                model: Services.DisplayService.draftMonitors

                delegate: Rectangle {
                    id: displayPill

                    required property var modelData
                    readonly property bool selected: Services.DisplayService.monitorName(displayPill.modelData)
                        === Services.DisplayService.selectedName
                    readonly property color pillColor: displayPill.modelData.disabled
                        ? ThemeModule.Theme.overlay
                        : ThemeModule.Theme.accent

                    width: Math.min(displayPicker.width, Math.max(82, pillText.implicitWidth + pillState.implicitWidth + 26))
                    height: ThemeModule.Theme.controlHeightSmall
                    radius: ThemeModule.Theme.borderRadiusSmall
                    opacity: root.busy ? ThemeModule.Theme.disabledOpacity : 1.0
                    color: ThemeModule.Theme.alpha(pillColor,
                        selected ? ThemeModule.Theme.tintStrong : ThemeModule.Theme.tintSubtle)
                    border.width: ThemeModule.Theme.borderWidth
                    border.color: ThemeModule.Theme.alpha(pillColor,
                        selected ? ThemeModule.Theme.tintOutlineStrong : ThemeModule.Theme.tintOutline)

                    Accessible.role: Accessible.Button
                    Accessible.name: "Select " + Services.DisplayService.monitorName(displayPill.modelData)
                    Accessible.description: displayPill.modelData.disabled ? "Display off" : "Display on"
                    Accessible.onPressAction: Services.DisplayService.setSelected(displayPill.modelData.name)

                    Row {
                        anchors.centerIn: parent
                        spacing: ThemeModule.Theme.spacingTiny

                        Text {
                            id: pillText
                            width: Math.min(138, implicitWidth)
                            text: displayPill.modelData.name || "Display"
                            font.pixelSize: ThemeModule.Theme.fontSizeCaption
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: displayPill.modelData.disabled ? ThemeModule.Theme.subtext : ThemeModule.Theme.text
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            id: pillState
                            text: displayPill.modelData.disabled ? "Off" : "On"
                            font.pixelSize: ThemeModule.Theme.fontSizeMicro
                            font.family: ThemeModule.Theme.fontFamily
                            color: displayPill.pillColor
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.busy
                        hoverEnabled: true
                        cursorShape: root.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onClicked: Services.DisplayService.setSelected(displayPill.modelData.name)
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            visible: root.selectedMonitor !== null
            implicitHeight: editorColumn.implicitHeight + ThemeModule.Theme.spacingMedium * 2
            radius: ThemeModule.Theme.borderRadiusSmall
            color: ThemeModule.Theme.controlFill
            border.width: ThemeModule.Theme.borderWidth
            border.color: ThemeModule.Theme.controlBorder

            Column {
                id: editorColumn
                x: ThemeModule.Theme.spacingMedium
                y: ThemeModule.Theme.spacingMedium
                width: parent.width - ThemeModule.Theme.spacingMedium * 2
                spacing: ThemeModule.Theme.spacingSmall

                Row {
                    width: parent.width
                    spacing: ThemeModule.Theme.spacingSmall

                    Components.AppIcon {
                        name: "display"
                        size: ThemeModule.Theme.iconSizeMedium
                        iconColor: root.selectedEnabled ? ThemeModule.Theme.accent : ThemeModule.Theme.subtext
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        width: Math.max(40, parent.width - ThemeModule.Theme.iconSizeMedium - outputSwitch.width - ThemeModule.Theme.spacingSmall * 2)
                        spacing: ThemeModule.Theme.spacingMicro
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            width: parent.width
                            text: root.selectedMonitor ? (root.selectedMonitor.name || "Display") : ""
                            font.pixelSize: ThemeModule.Theme.fontSizeNormal
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: ThemeModule.Theme.text
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: root.selectedMonitor !== null && root.selectedMonitor.description !== ""
                            text: root.selectedMonitor ? root.selectedMonitor.description : ""
                            font.pixelSize: ThemeModule.Theme.fontSizeCaption
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.subtext
                            elide: Text.ElideRight
                        }
                    }

                    Components.ToggleSwitch {
                        id: outputSwitch
                        checked: root.selectedEnabled
                        enabled: root.selectedMonitor !== null
                            && !root.busy
                            && (root.selectedMonitor.disabled || Services.DisplayService.activeDraftCount() > 1)
                        activeColor: ThemeModule.Theme.accent
                        tooltipText: checked ? "Turn display off" : "Turn display on"
                        onToggled: function(state) {
                            Services.DisplayService.setSelectedEnabled(state);
                        }
                    }
                }

                Components.SelectRow {
                    id: layoutRow
                    visible: Services.DisplayService.draftMonitors.length > 1
                    enabled: !root.busy
                    label: "Layout"
                    value: root.layoutLabel(Services.DisplayService.draftLayoutMode)
                    onActivated: layoutMenu.open()

                    Controls.Menu {
                        id: layoutMenu
                        y: layoutRow.height

                        Controls.MenuItem {
                            focusPolicy: Qt.ClickFocus
                            text: "Single"
                            onTriggered: Services.DisplayService.setDraftLayoutMode("single")
                        }
                        Controls.MenuItem {
                            focusPolicy: Qt.ClickFocus
                            text: "Mirror"
                            enabled: Services.DisplayService.draftMonitors.length > 1
                            onTriggered: Services.DisplayService.setDraftLayoutMode("mirror")
                        }
                        Controls.MenuItem {
                            focusPolicy: Qt.ClickFocus
                            text: "Extend"
                            enabled: Services.DisplayService.draftMonitors.length > 1
                            onTriggered: Services.DisplayService.setDraftLayoutMode("extend")
                        }
                    }
                }

                Components.SelectRow {
                    id: positionRow
                    visible: Services.DisplayService.draftMonitors.length > 1
                    enabled: root.canPositionSelected && !root.busy
                    label: "Position"
                    value: root.positionLabel()
                    onActivated: positionMenu.open()

                    Controls.Menu {
                        id: positionMenu
                        y: positionRow.height

                        Controls.MenuItem {
                            focusPolicy: Qt.ClickFocus
                            text: "Left"
                            onTriggered: Services.DisplayService.arrangeSelected("left")
                        }
                        Controls.MenuItem {
                            focusPolicy: Qt.ClickFocus
                            text: "Right"
                            onTriggered: Services.DisplayService.arrangeSelected("right")
                        }
                        Controls.MenuItem {
                            focusPolicy: Qt.ClickFocus
                            text: "Above"
                            onTriggered: Services.DisplayService.arrangeSelected("above")
                        }
                        Controls.MenuItem {
                            focusPolicy: Qt.ClickFocus
                            text: "Below"
                            onTriggered: Services.DisplayService.arrangeSelected("below")
                        }
                    }
                }

                Components.SelectRow {
                    id: modeRow
                    enabled: root.selectedEnabled && root.selectedModeOptions.length > 0 && !root.busy
                    label: "Mode"
                    value: root.selectedMonitor ? root.modeText(root.selectedMonitor) : ""
                    onActivated: modeMenu.open()

                    Controls.Menu {
                        id: modeMenu
                        y: modeRow.height

                        Instantiator {
                            model: root.selectedModeOptions

                            delegate: Controls.MenuItem {
                                required property var modelData
                                focusPolicy: Qt.ClickFocus

                                text: Services.DisplayService.modeLabel(modelData)
                                checkable: true
                                checked: root.selectedMonitor !== null
                                    && Services.DisplayService.modesEquivalent(
                                        modelData,
                                        Services.DisplayService.monitorModeString(root.selectedMonitor)
                                    )
                                onTriggered: Services.DisplayService.setSelectedMode(modelData)
                            }

                            onObjectAdded: function(index, object) {
                                modeMenu.insertItem(index, object);
                            }

                            onObjectRemoved: function(index, object) {
                                modeMenu.removeItem(object);
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: ThemeModule.Theme.spacingSmall
                    visible: root.canControlSelectedBrightness

                    Text {
                        text: "Brightness"
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.subtext
                        width: 70
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Components.StyledSlider {
                        width: parent.width - 118
                        anchors.verticalCenter: parent.verticalCenter
                        from: Services.BrightnessService.minimumPercent
                        value: Services.BrightnessService.percent
                        enabled: root.canControlSelectedBrightness
                        progressColor: ThemeModule.Theme.yellow
                        onMoved: Services.BrightnessService.setPercent(value)
                        onWheelAdjusted: function(nextValue) {
                            Services.BrightnessService.setPercent(nextValue);
                        }
                        onPressedChanged: if (!pressed) Services.BrightnessService.commit()
                    }

                    Text {
                        text: Services.BrightnessService.percent + "%"
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.subtext
                        width: 32
                        horizontalAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
