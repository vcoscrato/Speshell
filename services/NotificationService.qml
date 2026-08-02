pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool dndEnabled: false
    property var notificationHistory: []
    property var activePopups: []
    property int popupCounter: 0
    property int refreshTick: 0

    function debugLog(message) {
        if (SystemState.debugLogging)
            console.log("[Speshell][Notifications] " + message);
    }

    function popupById(popupId) {
        for (var i = 0; i < root.activePopups.length; i++) {
            if (root.activePopups[i].popupId === popupId)
                return root.activePopups[i];
        }
        return null;
    }

    function removePopup(popupId) {
        var current = root.activePopups.slice();
        for (var i = 0; i < current.length; i++) {
            if (current[i].popupId === popupId) {
                current.splice(i, 1);
                break;
            }
        }
        root.activePopups = current;
        root.schedulePopupExpiry();
    }

    function dismissPopup(popupId) {
        var popup = root.popupById(popupId);
        if (!popup)
            return;
        root.removePopup(popupId);
        if (popup.notification && popup.notification.tracked)
            popup.notification.dismiss();
    }

    function expirePopup(popupId) {
        var popup = root.popupById(popupId);
        if (!popup)
            return;
        root.removePopup(popupId);
        if (popup.notification && popup.notification.tracked)
            popup.notification.expire();
    }

    function launchDesktopEntry(desktopEntryId) {
        var requested = String(desktopEntryId || "");
        if (requested === "")
            return false;
        var entries = DesktopEntries.applications && DesktopEntries.applications.values
            ? DesktopEntries.applications.values : [];
        for (var i = 0; i < entries.length; i++) {
            var id = String(entries[i].id || "");
            if (id === requested || id === requested + ".desktop"
                    || id.replace(/\.desktop$/, "") === requested.replace(/\.desktop$/, "")) {
                entries[i].execute();
                return true;
            }
        }
        return false;
    }

    function activatePopup(popupId) {
        var popup = root.popupById(popupId);
        if (!popup)
            return;
        if (popup.defaultAction) {
            popup.defaultAction.invoke();
            if (!popup.resident)
                root.removePopup(popupId);
            return;
        }
        root.launchDesktopEntry(popup.desktopEntry);
        root.dismissPopup(popupId);
    }

    function invokePopupAction(popupId, action) {
        var popup = root.popupById(popupId);
        if (!popup || !action)
            return;
        action.invoke();
        if (!popup.resident)
            root.removePopup(popupId);
    }

    function clearHistory() {
        root.notificationHistory = [];
    }

    function removeHistoryAt(index) {
        var current = root.notificationHistory.slice();
        if (index >= 0 && index < current.length) {
            current.splice(index, 1);
            root.notificationHistory = current;
        }
    }

    function timeoutForNotification(notification) {
        var requestedMilliseconds = Number(notification.expireTimeout);
        if (requestedMilliseconds === 0)
            return -1;
        if (isFinite(requestedMilliseconds) && requestedMilliseconds > 0)
            return Math.round(requestedMilliseconds);
        if (notification.urgency === 2)
            return 10000;
        if (notification.urgency === 0)
            return 3000;
        return 5000;
    }

    function notificationActions(notification) {
        var result = [];
        var defaultAction = null;
        var actions = notification.actions || [];
        for (var i = 0; i < actions.length; i++) {
            if (actions[i].identifier === "default")
                defaultAction = actions[i];
            else
                result.push({ text: actions[i].text || "Action", action: actions[i] });
        }
        return { defaultAction: defaultAction, actions: result };
    }

    function schedulePopupExpiry() {
        popupExpiryTimer.stop();
        var now = Date.now();
        var earliest = -1;
        for (var i = 0; i < root.activePopups.length; i++) {
            var expiresAt = Number(root.activePopups[i].expiresAt);
            if (expiresAt >= 0 && (earliest < 0 || expiresAt < earliest))
                earliest = expiresAt;
        }
        if (earliest >= 0) {
            popupExpiryTimer.interval = Math.max(1, earliest - now);
            popupExpiryTimer.start();
        }
    }

    function expireDuePopups() {
        var now = Date.now();
        var due = [];
        for (var i = 0; i < root.activePopups.length; i++) {
            var popup = root.activePopups[i];
            if (popup.expiresAt >= 0 && popup.expiresAt <= now)
                due.push(popup.popupId);
        }
        for (var j = 0; j < due.length; j++)
            root.expirePopup(due[j]);
        root.schedulePopupExpiry();
    }

    function addNotification(notification) {
        if (!notification)
            return;
        root.debugLog("received app='" + (notification.appName || "")
            + "' urgency=" + notification.urgency + " dnd=" + root.dndEnabled);

        var receivedAt = new Date();
        var actions = root.notificationActions(notification);
        if (!notification.transient) {
            var history = [];
            for (var historyIndex = 0; historyIndex < root.notificationHistory.length; historyIndex++) {
                if (root.notificationHistory[historyIndex].id !== notification.id)
                    history.push(root.notificationHistory[historyIndex]);
            }
            history.unshift({
                id: notification.id,
                desktopEntry: notification.desktopEntry,
                appName: notification.appName,
                appIcon: notification.appIcon,
                summary: notification.summary,
                body: notification.body,
                urgency: notification.urgency,
                time: receivedAt
            });
            root.notificationHistory = history.slice(0, 50);
        }

        if (!root.dndEnabled) {
            var popupId = root.popupCounter++;
            var timeout = root.timeoutForNotification(notification);
            var popupObj = {
                popupId: popupId,
                id: notification.id,
                desktopEntry: notification.desktopEntry,
                appName: notification.appName,
                appIcon: notification.appIcon,
                image: notification.image,
                summary: notification.summary,
                body: notification.body,
                urgency: notification.urgency,
                time: receivedAt,
                notification: notification,
                defaultAction: actions.defaultAction,
                actions: actions.actions,
                resident: notification.resident,
                expiresAt: timeout < 0 ? -1 : Date.now() + timeout
            };

            notification.closed.connect(function() { root.removePopup(popupId); });
            var currentPopups = root.activePopups.slice();
            currentPopups.push(popupObj);
            if (currentPopups.length > 5) {
                var evicted = currentPopups.shift();
                if (evicted.notification && evicted.notification.tracked)
                    evicted.notification.expire();
            }
            root.activePopups = currentPopups;
            root.schedulePopupExpiry();
        } else if (notification.tracked) {
            notification.expire();
        }
    }

    Timer {
        interval: 30000
        running: SystemState.dashboardVisible
        repeat: true
        onTriggered: root.refreshTick++
    }

    Timer {
        id: popupExpiryTimer
        repeat: false
        onTriggered: root.expireDuePopups()
    }
}
