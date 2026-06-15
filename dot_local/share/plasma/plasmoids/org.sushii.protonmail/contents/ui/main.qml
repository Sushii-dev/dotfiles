import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string pmail: "$HOME/.local/bin/pmail"
    property int unread: -1
    property bool errored: false

    toolTipMainText: "Proton Mail"
    toolTipSubText: errored ? "Bridge unreachable"
                            : (unread < 0 ? "Checking…"
                                          : (unread + " unread in Inbox"))

    preferredRepresentation: compactRepresentation

    // run pmail unread via the executable engine
    Plasma5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source)
            var out = (data["stdout"] || "").trim()
            var code = data["exit code"]
            if (code === 0 && out.length && !isNaN(parseInt(out))) {
                root.unread = parseInt(out)
                root.errored = false
            } else {
                root.errored = true
            }
        }
        function poll() { connectedSources = [ root.pmail + " unread" ] }
        function exec(cmd) { connectedSources = [ cmd ] }
    }

    Timer {
        interval: 120000   // 2 min
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: runner.poll()
    }

    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                runner.poll()          // middle-click = force refresh
            } else {
                runner.exec("proton-mail")
            }
        }

        Kirigami.Icon {
            id: icon
            anchors.fill: parent
            source: "proton-mail"
            active: compact.containsMouse
        }

        // unread badge
        Rectangle {
            visible: root.unread > 0
            anchors.right: parent.right
            anchors.top: parent.top
            width: Math.max(height, badge.implicitWidth + Kirigami.Units.smallSpacing)
            height: Math.round(parent.height * 0.5)
            radius: height / 2
            color: Kirigami.Theme.negativeTextColor
            PlasmaComponents.Label {
                id: badge
                anchors.centerIn: parent
                text: root.unread > 99 ? "99+" : root.unread
                color: "white"
                font.pixelSize: Math.round(parent.height * 0.7)
                font.bold: true
            }
        }
    }

    // expanded view: a small panel listing latest unread is overkill for v1;
    // keep it simple — icon + badge, click opens the app.
}
