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
        property: "workspaceVisible"
        value: specialWorkspace.active
    }

    LazyLoader {
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

    IpcHandler {
        target: "activity"

        function publish(id: string, state: string, label: string, detail: string,
                         iconName: string, tone: string): void {
            Services.ActivityService.publish("ipc", {
                id: id,
                state: state,
                label: label,
                detail: detail,
                iconName: iconName,
                tone: tone,
                priority: 50
            });
        }

        function clear(id: string): void { Services.ActivityService.clear("ipc", id); }
        function list(): string { return Services.ActivityService.listJson(); }
        function refresh(): void { processActivities.refresh(); }
    }

    IpcHandler {
        target: "tool"

        function run(name: string, mode: string): bool { return Services.ToolsService.run(name, mode); }
        function list(): string {
            return Services.ToolsService.tools.map(function(tool) { return tool.id + "\t" + tool.label; }).join("\n");
        }
    }

    IpcHandler {
        target: "theme"

        function list(): string {
            return Services.ThemeService.themes.map(function(theme) { return theme.id + "\t" + theme.name; }).join("\n");
        }
        function get(): string { return Services.ThemeService.themeId; }
        function set(id: string): bool { return Services.ThemeService.setTheme(id); }
        function shuffle(id: string): bool { return Services.ThemeService.shuffle(id === "*" ? "" : id); }
        function rescan(): void { Services.ThemeService.scan(); }
    }

    IpcHandler {
        target: "wallpaper"

        function set(path: string): bool { return Services.ThemeService.setWallpaper(path); }
        function get(): string { return Services.ThemeService.wallpaper; }
    }

    Services.ActivityProcessAdapter {
        id: processActivities
    }

    Variants {
        model: Services.ThemeService.wallpaperEnabled ? Quickshell.screens : []

        WallpaperWindow {}
    }

    Variants {
        model: root.config && root.config.bar.position !== "off" ? Quickshell.screens : []

        Bar {
            config: root.config
        }
    }

    LauncherOverlay {
        id: launcherOverlay
        config: root.config
    }

    VolumeOsdWindow {}

    ActivityOsdWindow {}

    NotificationToastWindow {}
}
