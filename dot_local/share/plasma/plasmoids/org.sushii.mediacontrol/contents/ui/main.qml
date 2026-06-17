import QtQuick
import QtQml
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import org.kde.plasma.private.volume as Volume

PlasmoidItem {
    id: root

    // Visualization is handled by the sibling Kurve widget; this widget is the
    // "Media & Audio" hub: a compact icon trigger whose popup carries now-playing
    // + transport + output device + per-app mixer/routing + mic.

    // ---- mpris ----
    readonly property var player: mprisModel.currentPlayer
    readonly property bool hasPlayer: player !== null && player !== undefined
    readonly property bool isPlaying: hasPlayer && player.playbackStatus === Mpris.PlaybackStatus.Playing
    property double trackPos: 0   // microseconds, polled

    // ---- audio ----
    readonly property int normalVol: 65536
    property var defaultSink: null
    property var defaultSource: null
    function findDefaultSink() {
        for (var i = 0; i < sinkFinder.count; ++i) {
            var it = sinkFinder.objectAt(i);
            if (it && it.po && it.po["default"]) { defaultSink = it.po; return; }
        }
    }
    function findDefaultSource() {
        for (var i = 0; i < sourceFinder.count; ++i) {
            var it = sourceFinder.objectAt(i);
            if (it && it.po && it.po["default"]) { defaultSource = it.po; return; }
        }
    }
    // description of the sink a stream is routed to (by PulseObject.index)
    function sinkDescForIndex(idx) {
        for (var i = 0; i < sinkFinder.count; ++i) {
            var it = sinkFinder.objectAt(i);
            if (it && it.po && it.po.index === idx) return it.po.description;
        }
        return "Default";
    }

    Plasmoid.icon: isPlaying ? "media-playback-start" : "multimedia-volume-control"
    toolTipMainText: hasPlayer ? (player.track || "Media") : "Media & Audio"
    toolTipSubText: hasPlayer ? (player.artist || "") : "No media playing"

    // ===================== DATA MODELS =====================
    Mpris.Mpris2Model { id: mprisModel }

    Volume.SinkModel { id: sinkModel }
    Volume.SourceModel { id: sourceModel }
    Volume.SinkInputModel { id: sinkInputModel }

    Instantiator {
        id: sinkFinder
        model: sinkModel
        delegate: QtObject {
            property var po: model.PulseObject
            property bool isDefault: po ? po["default"] : false
            onIsDefaultChanged: if (isDefault) root.defaultSink = po
            Component.onCompleted: if (isDefault) root.defaultSink = po
        }
        onCountChanged: root.findDefaultSink()
    }
    Instantiator {
        id: sourceFinder
        model: sourceModel
        delegate: QtObject {
            property var po: model.PulseObject
            property bool isDefault: po ? po["default"] : false
            onIsDefaultChanged: if (isDefault) root.defaultSource = po
            Component.onCompleted: if (isDefault) root.defaultSource = po
        }
        onCountChanged: root.findDefaultSource()
    }

    // ===================== HELPERS =====================
    function fmtTime(usec) {
        if (!usec || usec < 0) return "0:00";
        var s = Math.floor(usec / 1000000);
        var m = Math.floor(s / 60);
        var sec = s % 60;
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }
    function volPct(obj) {
        if (!obj) return 0;
        return Math.round(obj.volume / normalVol * 100);
    }
    function setVol(obj, pct) {
        if (!obj) return;
        obj.muted = false;
        obj.volume = Math.round(Math.max(0, Math.min(100, pct)) / 100 * normalVol);
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying && root.expanded
        onTriggered: { if (root.hasPlayer) root.trackPos = root.player.position; }
    }

    Component.onCompleted: {
        findDefaultSink();
        findDefaultSource();
    }
    onExpandedChanged: if (root.expanded) { findDefaultSink(); findDefaultSource(); }

    // ===================== COMPACT (PANEL) =====================
    preferredRepresentation: compactRepresentation
    compactRepresentation: CompactRepresentation {}

    // ===================== FULL (POPUP) =====================
    fullRepresentation: Item {
        id: fullRoot
        readonly property int gu: Kirigami.Units.gridUnit
        Layout.preferredWidth: gu * 25
        Layout.preferredHeight: gu * 34
        Layout.minimumWidth: gu * 22
        Layout.minimumHeight: gu * 26

        // reusable translucent card colour
        readonly property color cardColor: Qt.rgba(Kirigami.Theme.textColor.r,
                                                    Kirigami.Theme.textColor.g,
                                                    Kirigami.Theme.textColor.b, 0.05)
        readonly property color lineColor: Qt.rgba(Kirigami.Theme.textColor.r,
                                                    Kirigami.Theme.textColor.g,
                                                    Kirigami.Theme.textColor.b, 0.1)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            // =========== NOW PLAYING CARD ===========
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: nowPlayingCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: Kirigami.Units.largeSpacing
                color: fullRoot.cardColor
                clip: true

                ColumnLayout {
                    id: nowPlayingCol
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.largeSpacing

                        Rectangle {
                            Layout.preferredWidth: fullRoot.gu * 4.5
                            Layout.preferredHeight: fullRoot.gu * 4.5
                            radius: Kirigami.Units.smallSpacing
                            clip: true
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                                           Kirigami.Theme.textColor.b, 0.08)
                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: parent.width * 0.5; height: width
                                source: "audio-x-generic"
                                visible: !art.visible
                            }
                            Image {
                                id: art
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: root.hasPlayer && root.player.artUrl ? root.player.artUrl : ""
                                visible: status === Image.Ready && source != ""
                                asynchronous: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: root.hasPlayer ? (root.player.track || "Unknown track") : "Nothing playing"
                                elide: Text.ElideRight
                                font.weight: Font.Bold
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: root.hasPlayer ? (root.player.artist || "") : "Play something to get started"
                                elide: Text.ElideRight
                                opacity: 0.7
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: root.hasPlayer && root.player.identity ? root.player.identity : ""
                                elide: Text.ElideRight
                                opacity: 0.45
                                font.pointSize: Kirigami.Theme.smallFont.pointSize
                                visible: text !== ""
                            }
                        }
                    }

                    // seek
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        visible: root.hasPlayer
                        QQC2.Slider {
                            id: seek
                            Layout.fillWidth: true
                            from: 0
                            to: root.hasPlayer && root.player.length > 0 ? root.player.length : 1
                            value: root.trackPos
                            enabled: root.hasPlayer && root.player.canSeek
                            onMoved: { if (root.hasPlayer) root.player.position = value; }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            PlasmaComponents.Label {
                                text: root.fmtTime(root.trackPos)
                                opacity: 0.6; font.pointSize: Kirigami.Theme.smallFont.pointSize
                            }
                            Item { Layout.fillWidth: true }
                            PlasmaComponents.Label {
                                text: root.hasPlayer ? root.fmtTime(root.player.length) : "0:00"
                                opacity: 0.6; font.pointSize: Kirigami.Theme.smallFont.pointSize
                            }
                        }
                    }

                    // transport
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Kirigami.Units.largeSpacing
                        enabled: root.hasPlayer
                        PlasmaComponents.ToolButton {
                            icon.name: "media-skip-backward"
                            enabled: root.hasPlayer && root.player.canGoPrevious
                            onClicked: root.player.Previous()
                            display: QQC2.AbstractButton.IconOnly
                        }
                        PlasmaComponents.Button {
                            icon.name: root.isPlaying ? "media-playback-pause" : "media-playback-start"
                            enabled: root.hasPlayer && (root.isPlaying ? root.player.canPause : root.player.canPlay)
                            onClicked: root.player.PlayPause()
                            display: QQC2.AbstractButton.IconOnly
                            Layout.preferredWidth: fullRoot.gu * 2.6
                            Layout.preferredHeight: fullRoot.gu * 2.6
                        }
                        PlasmaComponents.ToolButton {
                            icon.name: "media-skip-forward"
                            enabled: root.hasPlayer && root.player.canGoNext
                            onClicked: root.player.Next()
                            display: QQC2.AbstractButton.IconOnly
                        }
                    }
                }
            }

            // =========== OUTPUT ===========
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                PlasmaComponents.Label {
                    text: "OUTPUT"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.weight: Font.Bold
                    opacity: 0.5
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: fullRoot.lineColor }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                PlasmaComponents.ToolButton {
                    icon.name: root.defaultSink && root.defaultSink.muted ? "audio-volume-muted"
                                                                          : "audio-volume-high"
                    onClicked: { if (root.defaultSink) root.defaultSink.muted = !root.defaultSink.muted; }
                    display: QQC2.AbstractButton.IconOnly
                }
                QQC2.ComboBox {
                    id: sinkBox
                    Layout.fillWidth: true
                    model: sinkModel
                    textRole: "Description"
                    currentIndex: {
                        if (!root.defaultSink) return -1;
                        for (var i = 0; i < sinkModel.count; ++i) {
                            var it = sinkFinder.objectAt(i);
                            if (it && it.po === root.defaultSink) return i;
                        }
                        return -1;
                    }
                    onActivated: function(idx) {
                        var it = sinkFinder.objectAt(idx);
                        if (it && it.po) it.po["default"] = true;
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                QQC2.Slider {
                    Layout.fillWidth: true
                    from: 0; to: 100
                    value: root.volPct(root.defaultSink)
                    onMoved: root.setVol(root.defaultSink, value)
                }
                PlasmaComponents.Label {
                    text: root.volPct(root.defaultSink) + "%"
                    Layout.preferredWidth: fullRoot.gu * 2.5
                    horizontalAlignment: Text.AlignRight
                    opacity: 0.7
                }
            }

            // =========== VOLUME MIXER (per-app + routing) ===========
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing
                PlasmaComponents.Label {
                    text: "APPS"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.weight: Font.Bold
                    opacity: 0.5
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: fullRoot.lineColor }
            }
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                ListView {
                    id: appList
                    model: sinkInputModel
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.Label {
                        anchors.centerIn: parent
                        visible: appList.count === 0
                        text: "No applications playing audio"
                        opacity: 0.4
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: appRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                        radius: Kirigami.Units.smallSpacing
                        color: fullRoot.cardColor
                        readonly property var po: model.PulseObject

                        RowLayout {
                            id: appRow
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                Layout.preferredWidth: fullRoot.gu * 1.6
                                Layout.preferredHeight: fullRoot.gu * 1.6
                                Layout.alignment: Qt.AlignVCenter
                                source: (po && po.iconName) ? po.iconName : "audio-card"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Kirigami.Units.smallSpacing
                                    PlasmaComponents.Label {
                                        Layout.fillWidth: true
                                        text: (po && po.client && po.client.name) ? po.client.name
                                              : (model.Name || "Application")
                                        elide: Text.ElideRight
                                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                                        font.weight: Font.Bold
                                    }
                                    // routing chip: which output this app plays to
                                    PlasmaComponents.ToolButton {
                                        icon.name: "audio-speakers-symbolic"
                                        text: po ? root.sinkDescForIndex(po.deviceIndex) : ""
                                        display: QQC2.AbstractButton.TextBesideIcon
                                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                                        flat: true
                                        onClicked: routeMenu.open()

                                        QQC2.Menu {
                                            id: routeMenu
                                            Repeater {
                                                model: sinkModel
                                                delegate: QQC2.MenuItem {
                                                    text: model.Description
                                                    checkable: true
                                                    checked: po && model.PulseObject
                                                             && po.deviceIndex === model.PulseObject.index
                                                    onTriggered: {
                                                        if (po && model.PulseObject)
                                                            po.deviceIndex = model.PulseObject.index;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Kirigami.Units.smallSpacing
                                    PlasmaComponents.ToolButton {
                                        icon.name: (po && po.muted) ? "audio-volume-muted" : "audio-volume-high"
                                        display: QQC2.AbstractButton.IconOnly
                                        flat: true
                                        onClicked: { if (po) po.muted = !po.muted; }
                                    }
                                    QQC2.Slider {
                                        Layout.fillWidth: true
                                        from: 0; to: 100
                                        value: po ? Math.round(po.volume / root.normalVol * 100) : 0
                                        onMoved: { if (po) po.volume = Math.round(value / 100 * root.normalVol); }
                                    }
                                    PlasmaComponents.Label {
                                        text: (po ? Math.round(po.volume / root.normalVol * 100) : 0) + "%"
                                        Layout.preferredWidth: fullRoot.gu * 2.2
                                        horizontalAlignment: Text.AlignRight
                                        opacity: 0.6
                                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =========== INPUT (MIC) ===========
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                visible: root.defaultSource !== null
                PlasmaComponents.Label {
                    text: "INPUT"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.weight: Font.Bold
                    opacity: 0.5
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: fullRoot.lineColor }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                visible: root.defaultSource !== null
                PlasmaComponents.ToolButton {
                    icon.name: root.defaultSource && root.defaultSource.muted ? "microphone-sensitivity-muted"
                                                                              : "microphone-sensitivity-high"
                    onClicked: { if (root.defaultSource) root.defaultSource.muted = !root.defaultSource.muted; }
                    display: QQC2.AbstractButton.IconOnly
                }
                QQC2.Slider {
                    Layout.fillWidth: true
                    from: 0; to: 100
                    value: root.volPct(root.defaultSource)
                    onMoved: root.setVol(root.defaultSource, value)
                }
                PlasmaComponents.Label {
                    text: root.volPct(root.defaultSource) + "%"
                    Layout.preferredWidth: fullRoot.gu * 2.5
                    horizontalAlignment: Text.AlignRight
                    opacity: 0.7
                }
            }
        }
    }
}
