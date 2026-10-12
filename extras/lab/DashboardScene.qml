import QtQuick
import Quickshell

// Mimics Speshell's dashboard host: a mock dashboard in THEME_INI's colors, filled with
// the effects' backdrop, and the effects' dashboard transition bound the way
// core/DashboardPanel.qml binds it. The dashboard opens at t=0.
Item {
    id: root
    width: 1920
    height: 1080
    property real labTime: 0
    // Transition speed, as Speshell's transition host passes it to EffectClock.
    readonly property real timeScale: Number(Quickshell.env("SPEED") || 1)

    property var effects: {
        const component = Qt.createComponent("file://" + Quickshell.env("EFFECTS_DIR") + "/Effects.qml");
        if (component.status !== Component.Ready) {
            console.error(component.errorString());
            return null;
        }
        return component.createObject(root);
    }

    // Theme.qml's color names, from THEME_INI's [Colors].
    ThemePalette {
        id: swatch
    }

    Image {
        anchors.fill: parent
        source: "file://" + Quickshell.env("WALL_A")
        fillMode: Image.PreserveAspectCrop
    }

    MockDashboard {
        id: panel
        x: 16
        y: 16
        width: 420
        height: root.height - 32
        theme: swatch
        backdrop: root.effects && ("dashboardBackdrop" in root.effects) ? root.effects.dashboardBackdrop : null
    }

    // Like Speshell, destroy the transition as soon as it reports it finished.
    property bool entering: true

    Item {
        x: panel.x
        y: panel.y
        width: panel.width
        height: panel.height

        Loader {
            id: transition
            anchors.fill: parent
            active: root.entering
            sourceComponent: root.effects && ("dashboardTransition" in root.effects) ? root.effects.dashboardTransition : null
        }
    }

    Component.onCompleted: {
        if (transition.sourceComponent === null) {
            console.log("no dashboard transition");
            root.entering = false;
        }
    }

    Binding { target: transition.item; property: "panel"; value: panel }
    Binding { target: transition.item; property: "panelRect"; value: Qt.rect(0, 0, panel.width, panel.height) }
    Binding { target: transition.item; property: "theme"; value: swatch }

    Connections {
        target: transition.item
        ignoreUnknownSignals: true
        function onFinished() {
            console.log("dashboard transition finished at", root.labTime.toFixed(2));
            root.entering = false;
        }
    }
}
