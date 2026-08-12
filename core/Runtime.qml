//@ pragma UseQApplication
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../services" as Services

Scope {
    id: root

    function openLauncher() {
        launcherOverlay.openLauncher();
    }

    property var config: null
    property bool startupAssessmentComplete: false

    function reportStartupIssues() {
        if (root.startupAssessmentComplete || !Services.FeatureSupport.issuesReady)
            return;
        root.startupAssessmentComplete = true;
        var issues = Services.FeatureSupport.issues || [];
        if (issues.length === 0)
            return;
        Services.NotificationService.addInternalNotification(
            "configured-features",
            "Some configured features are unavailable",
            issues.map(function(issue) { return issue.detail; }).join("\n")
        );
    }

    Connections {
        target: Services.FeatureSupport
        function onIssuesReadyChanged() { Qt.callLater(root.reportStartupIssues); }
    }

    Component.onCompleted: root.reportStartupIssues()

    NotificationServer {
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: function(notification) {
            notification.tracked = true;
            Services.NotificationService.addNotification(notification);
        }
    }

    SpecialWorkspaceTracker {
        id: specialWorkspace
        enabled: root.config !== null
        workspaceName: root.config ? root.config.panelWorkspace : "special:term"
    }

    Binding {
        target: Services.DashboardService
        property: "workspaceName"
        value: root.config ? root.config.panelWorkspace : "special:term"
    }

    Binding {
        target: Services.DashboardService
        property: "workspaceVisible"
        value: specialWorkspace.active
    }

    LazyLoader {
        id: panelLoader
        active: root.config !== null

        component: DashboardPanel {
            config: root.config
            workspaceVisible: specialWorkspace.active
            targetScreen: specialWorkspace.screen
        }
    }

    IpcHandler {
        target: "launcher"

        function open() { root.openLauncher(); }
        function close() { launcherOverlay.closeLauncher(); }
        function toggle() { launcherOverlay.toggleLauncher(); }
    }

    LauncherOverlay {
        id: launcherOverlay
        config: root.config
    }

    VolumeOsdWindow {}

    NotificationToastWindow {}
}
