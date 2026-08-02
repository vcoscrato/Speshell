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
    readonly property var dashboardSurface: panelLoader.item
    readonly property bool dashboardVisible: root.dashboardSurface
        ? root.dashboardSurface.dashboardVisible
        : false
    readonly property bool dashboardActive: root.dashboardSurface
        ? root.dashboardSurface.dashboardActive
        : false

    onDashboardVisibleChanged: Services.SystemState.setDashboardState(root.dashboardVisible, root.dashboardActive)
    onDashboardActiveChanged: Services.SystemState.setDashboardState(root.dashboardVisible, root.dashboardActive)

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

    NotificationToastWindow {}

    Component.onCompleted: Services.SystemState.setDashboardState(root.dashboardVisible, root.dashboardActive)
}
