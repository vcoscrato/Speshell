pragma ComponentBehavior: Bound
// qmllint disable uncreatable-type unqualified unresolved-type
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services" as Services
import "../theme" as ThemeModule

// A transient card over everything on the focused screen that never takes focus:
// present() pops `card` in, dismiss() fades it out and then unmaps the window.
PanelWindow {
    id: root

    required property Item card
    // Where the card's pop-in starts.
    property real entranceScale: 0.96
    property bool shown: false
    property var targetScreen: null

    signal hidden()

    function present() {
        if (exitAnimation.running) {
            exitAnimation.stop();
            root.card.opacity = 1;
        }
        if (root.shown)
            return;
        root.targetScreen = Services.DashboardService.focusedScreen();
        root.card.opacity = 0;
        root.card.scale = root.entranceScale;
        root.shown = true;
        entranceAnimation.restart();
    }

    function dismiss() {
        if (root.shown)
            exitAnimation.restart();
    }

    screen: root.targetScreen
    visible: root.shown && root.targetScreen !== null
    color: "transparent"
    focusable: false
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    ParallelAnimation {
        id: entranceAnimation

        NumberAnimation {
            target: root.card
            property: "opacity"
            to: 1
            duration: ThemeModule.Theme.animDuration
            easing.type: ThemeModule.Theme.animEasing
        }

        NumberAnimation {
            target: root.card
            property: "scale"
            to: 1
            duration: ThemeModule.Theme.animDuration
            easing.type: Easing.OutBack
        }
    }

    NumberAnimation {
        id: exitAnimation
        target: root.card
        property: "opacity"
        to: 0
        duration: ThemeModule.Theme.motion ? 140 : 0
        easing.type: Easing.InCubic
        // Also stopped, short of the end, when present() takes the card back.
        onStopped: {
            if (root.card.opacity <= 0) {
                root.shown = false;
                root.hidden();
            }
        }
    }
}
