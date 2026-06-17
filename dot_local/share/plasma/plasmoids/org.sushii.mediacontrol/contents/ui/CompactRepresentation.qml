import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

/*
 * CompactRepresentation — the "Media & Audio" hub trigger.
 *
 * Visualization + now-playing text live in the sibling Kurve + MediaBar
 * widgets; this is just a compact square button (album art when playing, else
 * a media/audio icon) that opens the full hub popup.
 */
Item {
    id: compactRoot

    readonly property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical
    readonly property bool hasArt: root.hasPlayer && root.player.artUrl && art.status === Image.Ready

    Layout.fillHeight: horizontal
    Layout.fillWidth: !horizontal
    readonly property int side: Math.min(width, height)
    Layout.preferredWidth: horizontal ? height : -1
    Layout.preferredHeight: horizontal ? -1 : width
    Layout.minimumWidth: horizontal ? Kirigami.Units.iconSizes.small : -1

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded

        Rectangle {
            anchors.fill: parent
            radius: Kirigami.Units.smallSpacing
            color: (mouseArea.containsMouse || root.expanded)
                   ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g,
                             Kirigami.Theme.highlightColor.b, 0.15)
                   : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        // album art thumbnail when available
        Rectangle {
            anchors.centerIn: parent
            width: Math.round(compactRoot.side * 0.74)
            height: width
            radius: Kirigami.Units.smallSpacing
            clip: true
            visible: compactRoot.hasArt
            color: "transparent"
            Image {
                id: art
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                source: root.hasPlayer && root.player.artUrl ? root.player.artUrl : ""
            }
        }

        // fallback icon
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.round(compactRoot.side * 0.62)
            height: width
            visible: !compactRoot.hasArt
            source: root.isPlaying ? "media-playback-start" : "multimedia-volume-control"
        }
    }
}
