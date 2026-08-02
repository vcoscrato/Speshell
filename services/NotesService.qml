pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "." as AppServices

Singleton {
    id: root

    readonly property string notesPath: AppServices.ConfigService.dataDir !== ""
        ? AppServices.ConfigService.dataDir + "/scratchpad.txt" : ""

    property string text: ""
    property string savedText: ""
    property string writeText: ""
    property string errorText: ""
    property bool loaded: false
    property bool dirty: false
    property bool saving: false
    property bool saveQueued: false

    function finishInitialLoad(initialText) {
        if (root.loaded)
            return;
        root.text = initialText;
        root.savedText = initialText;
        root.loaded = true;
        root.dirty = false;
    }

    function read() {
        if (root.notesPath === "" || root.loaded)
            return;
        notesFile.reload();
    }

    function setText(nextText) {
        if (!root.loaded)
            return;

        root.text = String(nextText);
        root.dirty = root.text !== root.savedText;
        if (root.dirty)
            saveTimer.restart();
    }

    function save() {
        if (!root.loaded || root.notesPath === "")
            return;
        if (root.saving) {
            root.saveQueued = true;
            return;
        }
        if (root.text === root.savedText) {
            root.dirty = false;
            return;
        }

        root.writeText = root.text;
        root.saving = true;
        root.dirty = false;
        root.errorText = "";
        notesFile.setText(root.writeText);
    }

    function finishSave(succeeded) {
        var writtenText = root.writeText;
        var queued = root.saveQueued;
        root.writeText = "";
        root.saveQueued = false;
        root.saving = false;

        if (succeeded) {
            root.savedText = writtenText;
            root.errorText = "";
        } else {
            root.errorText = "Could not save notes.";
        }

        root.dirty = root.text !== root.savedText;
        if (root.dirty && (succeeded || queued))
            root.save();
    }

    function flush(synchronous) {
        saveTimer.stop();
        if (!synchronous) {
            root.save();
            return;
        }

        notesFile.blockWrites = true;
        if (root.saving)
            notesFile.waitForJob();
        if (root.text !== root.savedText)
            root.save();
        notesFile.blockWrites = false;
    }

    FileView {
        id: notesFile
        path: root.notesPath
        atomicWrites: true
        blockWrites: false
        printErrors: false

        onLoaded: root.finishInitialLoad(notesFile.text())
        onLoadFailed: root.finishInitialLoad("")
        onSaved: root.finishSave(true)
        onSaveFailed: root.finishSave(false)
    }

    Timer {
        id: saveTimer
        interval: 700
        repeat: false
        onTriggered: root.save()
    }
}
