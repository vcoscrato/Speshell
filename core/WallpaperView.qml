pragma ComponentBehavior: Bound
import QtQuick
import "../services/ThemeProvider.js" as ThemeProvider
import "../theme" as ThemeModule

// Shows the wallpaper at `path`. On a change, the old image stays on top while the
// theme effects' wallpaper transition, or a plain fade, removes it.
Item {
    id: root

    property string path: ""
    // The current effects' wallpaper transition; read when a change starts.
    property Component transition: null
    property real pixelRatio: 1

    property Image shown: imageA
    property Image outgoing: null
    property bool transitionRunning: false
    property Component runningTransition: null

    function change() {
        var url = ThemeProvider.fileUrl(root.path);
        if (String(root.shown.source) === url)
            return;
        root.finishTransition();
        var next = root.shown === imageA ? imageB : imageA;
        if (root.shown.status === Image.Ready) {
            root.outgoing = root.shown;
            root.outgoing.z = 1;
        } else {
            root.shown.source = "";
        }
        next.z = 0;
        root.shown = next;
        next.source = url;
        root.startWhenLoaded();
    }

    function startWhenLoaded() {
        if (root.outgoing === null || root.transitionRunning || fade.running
                || root.shown.status === Image.Loading)
            return;
        root.runningTransition = root.transition;
        if (root.runningTransition !== null) {
            root.transitionRunning = true;
            safetyTimer.restart();
        } else {
            fade.start();
        }
    }

    function finishTransition() {
        safetyTimer.stop();
        fade.stop();
        if (root.outgoing !== null) {
            root.outgoing.source = "";
            root.outgoing.opacity = 1;
            root.outgoing.z = 0;
            root.outgoing = null;
        }
        root.transitionRunning = false;
    }

    // Deferred so a wallpaper change sees its new effects' transition.
    onPathChanged: Qt.callLater(root.change)
    Component.onCompleted: root.change()

    Image {
        id: imageA
        anchors.fill: parent
        sourceSize: Qt.size(root.width * root.pixelRatio, root.height * root.pixelRatio)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        onStatusChanged: root.startWhenLoaded()
    }

    Image {
        id: imageB
        anchors.fill: parent
        sourceSize: imageA.sourceSize
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        onStatusChanged: root.startWhenLoaded()
    }

    NumberAnimation {
        id: fade
        target: root.outgoing
        property: "opacity"
        to: 0
        duration: ThemeModule.Theme.animDurationSlow
        easing.type: ThemeModule.Theme.animEasing
        onFinished: root.finishTransition()
    }

    // An effects transition must emit finished(); this bounds a broken one.
    Timer {
        id: safetyTimer
        interval: 5000
        onTriggered: root.finishTransition()
    }

    // Effects wallpaper transition (see README "Effects"): draws above both
    // images and must hide the outgoing one, for example through a ShaderEffectSource
    // with hideSource.
    Loader {
        id: transitionLoader
        z: 2
        anchors.fill: parent
        active: root.transitionRunning && root.runningTransition !== null
        sourceComponent: root.runningTransition
    }

    Binding {
        target: transitionLoader.item
        property: "outgoing"
        value: root.outgoing
    }

    // Optional for effects; the new image cannot change while a transition runs.
    function offerIncoming(item) {
        if ("incoming" in item)
            item.incoming = root.shown;
    }

    Connections {
        target: transitionLoader

        function onLoaded() { root.offerIncoming(transitionLoader.item); }
    }

    Connections {
        target: transitionLoader.item
        ignoreUnknownSignals: true

        function onFinished() { root.finishTransition(); }
    }
}
