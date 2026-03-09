import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // State
    property int pendingCount: 0
    property bool isChecking: false
    property bool isUpdating: false
    property bool hasError: false
    property string errorMessage: ""
    property string lastCheck: ""

    // Settings
    property int checkInterval: pluginData.checkInterval || 300 // seconds

    readonly property string statusIcon: {
        if (isUpdating) return "sync";
        if (hasError) return "sync_problem";
        if (pendingCount > 0) return "update";
        return "check_circle";
    }

    readonly property color statusColor: {
        if (isUpdating) return Theme.primary;
        if (hasError) return Theme.error;
        if (pendingCount > 0) return Theme.warning;
        return Theme.surfaceText;
    }

    readonly property string tooltipText: {
        if (isUpdating) return "Updating dotfiles...";
        if (hasError) return "Chezmoi error: " + errorMessage;
        if (pendingCount > 0) return pendingCount + " update" + (pendingCount > 1 ? "s" : "") + " available — click to apply";
        return "Dotfiles up to date";
    }

    Component.onCompleted: {
        Qt.callLater(checkForUpdates);
    }

    Timer {
        id: checkTimer
        interval: root.checkInterval * 1000
        repeat: true
        running: !root.isUpdating
        onTriggered: root.checkForUpdates()
    }

    // Fetch + count commits behind
    function checkForUpdates() {
        if (isUpdating) return;
        isChecking = true;
        hasError = false;
        fetchProcess.running = true;
    }

    Process {
        id: fetchProcess
        command: ["chezmoi", "git", "--", "fetch", "-q"]
        running: false

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                countProcess.running = true;
            } else {
                root.isChecking = false;
                root.hasError = true;
                root.errorMessage = "fetch failed";
            }
        }
    }

    Process {
        id: countProcess
        command: ["sh", "-c", "chezmoi git -- log HEAD..origin/main --oneline 2>/dev/null | wc -l"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                root.pendingCount = parseInt(data.trim()) || 0;
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.isChecking = false;
            root.lastCheck = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            if (exitCode !== 0) {
                root.hasError = true;
                root.errorMessage = "status check failed";
            }
        }
    }

    // Update + apply
    function applyUpdate() {
        if (isUpdating || pendingCount === 0) return;
        isUpdating = true;
        hasError = false;
        updateProcess.running = true;
    }

    Process {
        id: updateProcess
        command: ["sh", "-c", "chezmoi update --force 2>&1"]
        running: false

        onExited: (exitCode, exitStatus) => {
            root.isUpdating = false;
            if (exitCode === 0) {
                root.pendingCount = 0;
                root.lastCheck = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                ToastService.show("Dotfiles updated successfully", "check_circle");
            } else {
                root.hasError = true;
                root.errorMessage = "update failed (exit " + exitCode + ")";
                ToastService.show("Chezmoi update failed", "error");
            }
        }
    }

    pillClickAction: () => {
        if (root.pendingCount > 0 && !root.isUpdating) {
            root.applyUpdate();
        } else {
            root.checkForUpdates();
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.statusIcon
                size: Theme.iconSize - 6
                color: root.statusColor
                anchors.verticalCenter: parent.verticalCenter

                RotationAnimator on rotation {
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: root.isUpdating || root.isChecking
                }
            }

            StyledText {
                text: root.pendingCount > 0 ? root.pendingCount.toString() : ""
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: root.statusColor
                anchors.verticalCenter: parent.verticalCenter
                visible: root.pendingCount > 0
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.statusIcon
                size: Theme.iconSize - 6
                color: root.statusColor
                anchors.horizontalCenter: parent.horizontalCenter

                RotationAnimator on rotation {
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: root.isUpdating || root.isChecking
                }
            }

            StyledText {
                text: root.pendingCount > 0 ? root.pendingCount.toString() : ""
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: root.statusColor
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.pendingCount > 0
            }
        }
    }
}
