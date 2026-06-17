import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

/*
 * Spotify controller. Transport + now-playing via playerctl (MPRIS); like/unlike
 * and playlist add/remove via pspot (Web API). The cava/XHR lessons apply: read
 * external state by polling a short-lived command through the executable engine
 * (Timer -> connectSource with a dedup-busting suffix -> parse -> disconnect).
 */
PlasmoidItem {
    id: root

    readonly property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical

    // now-playing state (from playerctl)
    property string trackId: ""          // bare 22-char id
    property string title: ""
    property string artist: ""
    property string artUrl: ""
    property string status: ""           // Playing / Paused / ""
    property double posSec: 0
    property double lenSec: 0
    readonly property bool running: status !== ""
    readonly property bool isPlaying: status === "Playing"

    // library state (from pspot)
    property bool liked: false
    property bool likedKnown: false
    property var playlists: []           // [{id,name,...}]
    property var contains: ({})          // plid -> bool
    property bool busy: false            // an action in flight

    Plasmoid.icon: "spotify"
    toolTipMainText: running ? title : "Spotify"
    toolTipSubText: running ? artist : "Not playing"

    // ===================== EXEC PLUMBING =====================
    P5Support.DataSource {
        id: pctl                         // fire-and-forget transport + polls
        engine: "executable"
        property int _c: 0
        connectedSources: []
        onNewData: function(src, data) {
            disconnectSource(src);
            var out = (data["stdout"] || "");
            if (src.indexOf("metadata") < 0) return;     // transport calls: ignore output
            root.parseNowPlaying(out);
        }
    }
    function pctlRun(cmd) { pctl.connectSource("playerctl -p spotify " + cmd + " # " + (pctl._c++)); }

    P5Support.DataSource {
        id: pspotProc                    // Web API helper (JSON out)
        engine: "executable"
        property int _c: 0
        connectedSources: []
        onNewData: function(src, data) {
            disconnectSource(src);
            root.busy = false;
            var out = (data["stdout"] || "").trim();
            if (out === "") return;
            var obj;
            try { obj = JSON.parse(out); } catch (e) { return; }
            root.handlePspot(src, obj);
        }
    }
    function pspotRun(args, tag) {
        // tag rides in a trailing comment so onNewData can route the reply
        pspotProc.connectSource("pspot " + args + " #" + tag + " " + (pspotProc._c++));
    }

    // ===================== POLL NOW-PLAYING =====================
    readonly property string fmt: "{{mpris:trackid}}\\t{{xesam:title}}\\t{{xesam:artist}}\\t{{mpris:artUrl}}\\t{{status}}\\t{{position}}\\t{{mpris:length}}"
    Timer {
        interval: 1000; repeat: true; running: true
        triggeredOnStart: true
        onTriggered: pctl.connectSource("playerctl -p spotify metadata --format '" + root.fmt + "' # " + (pctl._c++))
    }

    function parseNowPlaying(out) {
        out = (out || "").replace(/\n+$/, "");
        if (out === "" || out.indexOf("No player") >= 0) {
            status = ""; trackId = ""; title = ""; artist = ""; return;
        }
        // playerctl emits a LITERAL "\t" (backslash-t), not a real tab — split on that
        var p = out.split("\\t");
        if (p.length < 5) return;
        var rawId = p[0] || "";
        var m = rawId.match(/([A-Za-z0-9]{22})/);
        var newId = m ? m[1] : "";
        title = p[1] || "";
        artist = p[2] || "";
        artUrl = p[3] || "";
        status = p[4] || "";
        posSec = (parseInt(p[5]) || 0) / 1000000;
        lenSec = (parseInt(p[6]) || 0) / 1000000;
        if (newId !== trackId) {
            trackId = newId;
            likedKnown = false;
            if (trackId !== "") refreshLiked();
            contains = ({});
            if (root.expanded && trackId !== "") refreshContains();
        }
    }

    // ===================== LIBRARY ACTIONS =====================
    function refreshLiked() { if (trackId) pspotRun("saved " + trackId, "saved"); }
    function toggleLike() {
        if (!trackId) return;
        busy = true;
        if (liked) { liked = false; pspotRun("unsave " + trackId, "unsave"); }
        else { liked = true; pspotRun("save " + trackId, "save"); }
    }
    function loadPlaylists() { pspotRun("playlists", "playlists"); }
    function refreshContains() {
        for (var i = 0; i < playlists.length; ++i)
            pspotRun("contains " + playlists[i].id + " " + trackId, "contains:" + playlists[i].id);
    }
    function togglePlaylist(plid) {
        busy = true;
        var has = contains[plid] === true;
        var c = contains; c[plid] = !has; contains = c;     // optimistic
        pspotRun((has ? "remove " : "add ") + plid + " " + trackId, "pl:" + plid);
    }

    function handlePspot(src, obj) {
        if (obj.error) { likedKnown = true; return; }
        var tag = (src.split("#")[1] || "").split(" ")[0];
        if (tag === "saved") { liked = obj.saved === true; likedKnown = true; }
        else if (tag === "save" || tag === "unsave") { liked = obj.saved === true; likedKnown = true; }
        else if (tag === "playlists") { playlists = obj; if (trackId) refreshContains(); }
        else if (tag.indexOf("contains:") === 0) {
            var c = contains; c[tag.substring(9)] = obj.contains === true; contains = c;
        }
    }

    onExpandedChanged: {
        if (expanded) {
            if (playlists.length === 0) loadPlaylists();
            else if (trackId) refreshContains();
        }
    }

    // ===================== COMPACT (NAVBAR) =====================
    preferredRepresentation: compactRepresentation
    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = !root.expanded
        Layout.fillHeight: root.horizontal
        Layout.fillWidth: !root.horizontal
        Layout.preferredWidth: root.horizontal ? cRow.implicitWidth + Kirigami.Units.largeSpacing : -1

        Rectangle {
            anchors.fill: parent; radius: Kirigami.Units.smallSpacing
            color: compact.containsMouse ? root.acc(0.12) : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        RowLayout {
            id: cRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Icon {
                source: "spotify"
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                visible: !root.running
            }
            PlasmaComponents.Label {
                text: root.running ? (root.title + (root.artist ? " · " + root.artist : "")) : "Spotify"
                elide: Text.ElideRight
                Layout.maximumWidth: Kirigami.Units.gridUnit * 16
                font.weight: Font.Medium
            }
            PlasmaComponents.ToolButton {
                visible: root.running
                icon.name: root.liked ? "starred-symbolic" : "non-starred-symbolic"
                icon.color: root.liked ? root.accent : root.txt
                enabled: root.trackId !== "" && !root.busy
                display: QQC2.AbstractButton.IconOnly
                flat: true
                onClicked: root.toggleLike()
            }
        }
    }

    // ===================== FULL (POPUP) =====================
    fullRepresentation: Item {
        id: full
        readonly property int gu: Kirigami.Units.gridUnit
        Layout.preferredWidth: gu * 22
        Layout.preferredHeight: gu * 30
        Layout.minimumWidth: gu * 18
        Layout.minimumHeight: gu * 24
        readonly property color card: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.05)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            // now playing
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                Rectangle {
                    Layout.preferredWidth: full.gu * 5; Layout.preferredHeight: full.gu * 5
                    radius: Kirigami.Units.smallSpacing; clip: true; color: full.card
                    Kirigami.Icon { anchors.centerIn: parent; width: parent.width*0.5; height: width
                        source: "spotify"; visible: !cover.visible }
                    Image { id: cover; anchors.fill: parent; fillMode: Image.PreserveAspectCrop
                        asynchronous: true; source: root.artUrl
                        visible: status === Image.Ready && root.artUrl !== "" }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    PlasmaComponents.Label { Layout.fillWidth: true; text: root.running ? root.title : "Nothing playing"
                        font.weight: Font.Bold; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1; elide: Text.ElideRight }
                    PlasmaComponents.Label { Layout.fillWidth: true; text: root.artist; opacity: 0.7; elide: Text.ElideRight; visible: text !== "" }
                    PlasmaComponents.ToolButton {
                        text: root.liked ? "Liked" : "Like"
                        icon.name: root.liked ? "starred-symbolic" : "non-starred-symbolic"
                        icon.color: root.liked ? root.accent : root.txt
                        enabled: root.trackId !== "" && !root.busy
                        onClicked: root.toggleLike()
                    }
                }
            }

            // seek
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0; visible: root.running
                QQC2.Slider {
                    Layout.fillWidth: true; from: 0; to: root.lenSec > 0 ? root.lenSec : 1; value: root.posSec
                    onMoved: root.pctlRun("position " + Math.round(value))
                }
                RowLayout {
                    Layout.fillWidth: true
                    PlasmaComponents.Label { text: root.tfmt(root.posSec); opacity: 0.6; font.pointSize: Kirigami.Theme.smallFont.pointSize }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label { text: root.tfmt(root.lenSec); opacity: 0.6; font.pointSize: Kirigami.Theme.smallFont.pointSize }
                }
            }

            // transport
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: Kirigami.Units.largeSpacing; enabled: root.running
                PlasmaComponents.ToolButton { icon.name: "media-playlist-shuffle"; display: QQC2.AbstractButton.IconOnly; onClicked: root.pctlRun("shuffle toggle") }
                PlasmaComponents.ToolButton { icon.name: "media-skip-backward"; display: QQC2.AbstractButton.IconOnly; onClicked: root.pctlRun("previous") }
                PlasmaComponents.Button {
                    icon.name: root.isPlaying ? "media-playback-pause" : "media-playback-start"
                    display: QQC2.AbstractButton.IconOnly
                    Layout.preferredWidth: full.gu * 3; Layout.preferredHeight: full.gu * 3
                    onClicked: root.pctlRun("play-pause")
                }
                PlasmaComponents.ToolButton { icon.name: "media-skip-forward"; display: QQC2.AbstractButton.IconOnly; onClicked: root.pctlRun("next") }
                PlasmaComponents.ToolButton { icon.name: "media-playlist-repeat"; display: QQC2.AbstractButton.IconOnly; onClicked: root.pctlRun("loop Track") }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.1) }

            // playlists
            RowLayout {
                Layout.fillWidth: true
                PlasmaComponents.Label { text: "ADD TO PLAYLIST"; opacity: 0.5; font.weight: Font.Bold; font.pointSize: Kirigami.Theme.smallFont.pointSize }
                Item { Layout.fillWidth: true }
                PlasmaComponents.Label { text: root.playlists.length === 0 ? "(authorize: pspot auth)" : ""
                    opacity: 0.5; font.pointSize: Kirigami.Theme.smallFont.pointSize }
            }
            QQC2.ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; contentWidth: availableWidth
                ListView {
                    model: root.playlists
                    spacing: Kirigami.Units.smallSpacing
                    delegate: RowLayout {
                        width: ListView.view.width
                        readonly property bool inPl: root.contains[modelData.id] === true
                        PlasmaComponents.Label { Layout.fillWidth: true; text: modelData.name; elide: Text.ElideRight }
                        PlasmaComponents.ToolButton {
                            icon.name: parent.inPl ? "list-remove" : "list-add"
                            enabled: root.trackId !== "" && !root.busy
                            display: QQC2.AbstractButton.IconOnly
                            onClicked: root.togglePlaylist(modelData.id)
                        }
                    }
                }
            }
        }
    }

    // ===================== HELPERS =====================
    function tfmt(s) {
        s = Math.max(0, Math.floor(s));
        var m = Math.floor(s / 60), sec = s % 60;
        return m + ":" + (sec < 10 ? "0" : "") + sec;
    }
    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property color txt: Kirigami.Theme.textColor
    function acc(a) { return Qt.rgba(accent.r, accent.g, accent.b, a); }
}
