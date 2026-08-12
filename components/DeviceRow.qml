pragma ComponentBehavior: Bound

import QtQuick
import "../theme" as ThemeModule
import "." as Components

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string leadingIconName: ""
    property int signalLevel: -1
    property bool showLock: false
    property var badges: [] // [{text:"Known", tone:"success"}]

    property bool primaryEnabled: true
    property var actionChips: [] // [{text,tone,armed,enabled,actionId}]
    property bool controlsBelow: false

    property bool expanded: false
    default property alias expandedContent: expandedColumn.data

    signal primaryTriggered()
    signal actionTriggered(string actionId)

    function itemCount(items) {
        return items ? items.length : 0;
    }

    function signalIconName() {
        if (signalLevel < 0) return "";
        if (signalLevel > 75) return "wifi";
        if (signalLevel > 50) return "wifi-medium";
        if (signalLevel > 25) return "wifi-low";
        return "wifi-empty";
    }

    width: parent ? parent.width : 300
    radius: ThemeModule.Theme.borderRadiusSmall
    color: rowMouse.containsMouse ? ThemeModule.Theme.cardHover : "transparent"
    border.width: root.activeFocus ? 2 : 0
    border.color: ThemeModule.Theme.accent
    implicitHeight: contentColumn.implicitHeight + ThemeModule.Theme.spacingSmall * 2
    activeFocusOnTab: root.primaryEnabled

    Accessible.role: Accessible.Button
    Accessible.name: root.title
    Accessible.description: root.subtitle
    Accessible.onPressAction: if (root.primaryEnabled) root.primaryTriggered()

    Keys.onPressed: function(event) {
        if (!root.primaryEnabled || event.isAutoRepeat)
            return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.primaryTriggered();
            event.accepted = true;
        }
    }

    readonly property bool hasControls: root.itemCount(root.badges) > 0 || root.itemCount(root.actionChips) > 0
    readonly property bool hasLeadingVisual: root.leadingIconName !== ""
    readonly property real leadingVisualWidth: root.leadingIconName !== "" ? leadingAppIcon.width : 0

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.primaryEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.primaryEnabled) {
                root.forceActiveFocus();
                root.primaryTriggered();
            }
        }
    }

    Column {
        id: contentColumn
        z: 1
        anchors.fill: parent
        anchors.margins: ThemeModule.Theme.spacingSmall
        spacing: ThemeModule.Theme.spacingSmall

        Row {
            id: headRow
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall

            Components.AppIcon {
                id: leadingAppIcon
                name: root.leadingIconName
                size: 18
                iconColor: ThemeModule.Theme.text
                anchors.verticalCenter: parent.verticalCenter
                visible: root.leadingIconName !== ""
            }

            Components.AppIcon {
                id: signalLevelText
                name: root.signalIconName()
                size: 16
                iconColor: ThemeModule.Theme.accent
                anchors.verticalCenter: parent.verticalCenter
                visible: root.signalLevel >= 0
            }

            Text {
                id: titleText
                text: root.title
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                font.bold: true
                color: ThemeModule.Theme.text
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                width: root.controlsBelow
                    ? Math.max(40, Math.min(implicitWidth, parent.width * 0.46))
                    : Math.max(40, parent.width - subtitleText.implicitWidth - rightActions.implicitWidth
                        - (root.hasLeadingVisual ? root.leadingVisualWidth + ThemeModule.Theme.spacingSmall : 0)
                        - (root.signalLevel >= 0 ? signalLevelText.implicitWidth + ThemeModule.Theme.spacingSmall : 0)
                        - (root.showLock ? lockText.implicitWidth + ThemeModule.Theme.spacingSmall : 0)
                        - ThemeModule.Theme.spacingSmall * 4)
            }

            Components.AppIcon {
                id: lockText
                name: "lock"
                size: 12
                iconColor: ThemeModule.Theme.subtext
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showLock
            }

            Text {
                id: subtitleText
                text: root.subtitle
                font.pixelSize: 10
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext
                anchors.verticalCenter: parent.verticalCenter
                visible: text !== ""
                elide: Text.ElideRight
                width: root.controlsBelow
                    ? Math.max(0, parent.width - titleText.width
                        - (root.hasLeadingVisual ? root.leadingVisualWidth + ThemeModule.Theme.spacingSmall : 0)
                        - (root.signalLevel >= 0 ? signalLevelText.implicitWidth + ThemeModule.Theme.spacingSmall : 0)
                        - (root.showLock ? lockText.implicitWidth + ThemeModule.Theme.spacingSmall : 0)
                        - ThemeModule.Theme.spacingSmall * 4)
                    : implicitWidth
            }

            Item { width: 1; height: 1 }

            Row {
                id: rightActions
                spacing: ThemeModule.Theme.spacingTiny
                anchors.verticalCenter: parent.verticalCenter
                visible: !root.controlsBelow && root.hasControls

                Repeater {
                    model: root.badges
                    delegate: Components.StatusBadge {
                        id: inlineBadge
                        required property var modelData
                        text: inlineBadge.modelData.text || ""
                        tone: inlineBadge.modelData.tone || "neutral"
                    }
                }

                Repeater {
                    model: root.actionChips
                    delegate: Components.InlineActionChip {
                        id: inlineAction
                        required property var modelData
                        visible: true
                        text: inlineAction.modelData.text || ""
                        tone: inlineAction.modelData.tone || "neutral"
                        armed: !!inlineAction.modelData.armed
                        enabled: inlineAction.modelData.enabled !== false
                        onActivated: root.actionTriggered(inlineAction.modelData.actionId || "")
                    }
                }
            }
        }

        Flow {
            id: bottomActions
            visible: root.controlsBelow && root.hasControls
            width: parent.width
            spacing: ThemeModule.Theme.spacingTiny

            Repeater {
                model: root.badges
                delegate: Components.StatusBadge {
                    id: bottomBadge
                    required property var modelData
                    text: bottomBadge.modelData.text || ""
                    tone: bottomBadge.modelData.tone || "neutral"
                }
            }

            Repeater {
                model: root.actionChips
                delegate: Components.InlineActionChip {
                    id: bottomAction
                    required property var modelData
                    visible: true
                    text: bottomAction.modelData.text || ""
                    tone: bottomAction.modelData.tone || "neutral"
                    armed: !!bottomAction.modelData.armed
                    enabled: bottomAction.modelData.enabled !== false
                    onActivated: root.actionTriggered(bottomAction.modelData.actionId || "")
                }
            }
        }

        Column {
            id: expandedColumn
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: root.expanded
        }
    }

}
