import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

// Proton Calendar + Mail.
//   Compact: default Plasma icon (renders reliably here) — swaps to mail-unread when unread > 0.
//   Popup: LEFT inbox shortlist, RIGHT calendar (date header + month grid + a DAY TIMELINE
//   with proportional event blocks and a live "now" line). Today selected by default.
// Data: pmail (Bridge IMAP) + pcal (Proton ICS share feed).
PlasmoidItem {
    id: root

    property int unread: -1
    property bool mailErrored: false
    property var messages: []
    property var eventsByDate: ({})
    property bool calErrored: false

    property var displayDate: new Date()
    property var selectedDate: new Date()
    property int nowMinutes: 0

    Plasmoid.icon: (!mailErrored && unread > 0) ? "mail-unread" : "proton-mail"
    toolTipMainText: "Proton Calendar & Mail"
    toolTipSubText: mailErrored ? "Bridge unreachable"
                                : (unread < 0 ? "Checking…" : unread + " unread in Inbox")

    // ---------- data ----------
    Component.onCompleted: { tickNow(); refreshAll() }

    function tickNow() { const n = new Date(); root.nowMinutes = n.getHours() * 60 + n.getMinutes() }

    // live clock for the panel element (crisp minute flips)
    property var clock: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: { root.clock = new Date(); root.tickNow() } }

    // ongoing (or next) event today, for the panel — title only, "" if none
    function panelEventText() {
        const evs = timedEvents(new Date()).slice().sort((a, b) => a.start - b.start)
        const nm = root.nowMinutes
        for (let i = 0; i < evs.length; ++i)
            if (nm >= evMin(evs[i].start) && nm <= evMin(evs[i].end)) return evs[i].title
        for (let i = 0; i < evs.length; ++i)
            if (evMin(evs[i].start) > nm) return evs[i].title
        return ""
    }
    function panelEventOngoing() {
        const evs = timedEvents(new Date())
        const nm = root.nowMinutes
        for (let i = 0; i < evs.length; ++i)
            if (nm >= evMin(evs[i].start) && nm <= evMin(evs[i].end)) return true
        return false
    }

    // frequent auto-refresh — no manual refresh needed
    Timer { interval: 20000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { root.tickNow(); unreadSrc.poll(); listSrc.poll() } }
    Timer { interval: 300000; running: true; repeat: true; onTriggered: root.loadMonth() }
    // short debounce to refresh counts right after marking a mail read
    Timer { id: afterRead; interval: 1500; onTriggered: { unreadSrc.poll(); listSrc.poll() } }

    function refreshAll() { unreadSrc.poll(); listSrc.poll(); loadMonth() }
    function loadMonth() {
        const ym = root.displayDate.getFullYear() + "-" + ("0" + (root.displayDate.getMonth() + 1)).slice(-2)
        calSrc.connectedSources = ["$HOME/.local/bin/pcal month " + ym + " # " + Date.now()]
    }

    Plasma5Support.DataSource {
        id: unreadSrc; engine: "executable"; connectedSources: []
        onNewData: function (src, data) {
            disconnectSource(src)
            const n = parseInt(("" + (data["stdout"] || "")).trim())
            if (data["exit code"] === 0 && !isNaN(n)) { root.unread = n; root.mailErrored = false } else root.mailErrored = true
        }
        function poll() { connectedSources = ["$HOME/.local/bin/pmail unread # " + Date.now()] }
    }
    Plasma5Support.DataSource {
        id: listSrc; engine: "executable"; connectedSources: []
        onNewData: function (src, data) {
            disconnectSource(src)
            try { root.messages = JSON.parse("" + (data["stdout"] || "")) } catch (e) { root.messages = [] }
        }
        function poll() { connectedSources = ["$HOME/.local/bin/pmail list INBOX --limit 15 # " + Date.now()] }
    }
    Plasma5Support.DataSource {
        id: calSrc; engine: "executable"; connectedSources: []
        onNewData: function (src, data) {
            disconnectSource(src)
            try {
                const evs = JSON.parse("" + (data["stdout"] || ""))
                const map = {}
                for (let i = 0; i < evs.length; ++i) {
                    const e = evs[i]; const key = (e.start || "").slice(0, 10)
                    if (!key) continue
                    if (!map[key]) map[key] = []
                    map[key].push({ "title": e.title || "(no title)", "start": new Date(e.start),
                                    "end": e.end ? new Date(e.end) : new Date(e.start), "allDay": !!e.allDay, "location": e.location || "" })
                }
                root.eventsByDate = map; root.calErrored = false
            } catch (e) { root.calErrored = true }
        }
    }
    Plasma5Support.DataSource {
        id: exec; engine: "executable"; connectedSources: []
        onNewData: function (src, data) { disconnectSource(src) }
        function run(cmd) { connectedSources = [cmd] }
    }

    // ---------- in-popup reader ----------
    property var readingMail: null      // {from,subject,date,body} when open
    property string readingUrl: ""      // Proton web url for the open mail
    property bool readerLoading: false

    function openReader(uid, url) {
        if (!uid) return
        root.readingUrl = url || ""
        root.readingMail = null
        root.readerLoading = true
        // optimistic: clear the unread dot in the local list immediately
        var arr = root.messages.slice()
        var changed = false
        for (var i = 0; i < arr.length; ++i) {
            if (arr[i].uid === uid && arr[i].unread) {
                arr[i] = Object.assign({}, arr[i], { unread: false }); changed = true
            }
        }
        if (changed) { root.messages = arr; if (root.unread > 0) root.unread-- }
        readProc.connectedSources = ["$HOME/.local/bin/pmail read " + uid + " --mark # " + Date.now()]
    }
    function closeReader() { root.readingMail = null; root.readerLoading = false }

    Plasma5Support.DataSource {
        id: readProc; engine: "executable"; connectedSources: []
        onNewData: function (src, data) {
            disconnectSource(src)
            try { root.readingMail = JSON.parse("" + (data["stdout"] || "")) }
            catch (e) { root.readingMail = { "subject": "(failed to load)", "from": "", "date": "", "body": "" } }
            root.readerLoading = false
            afterRead.restart()   // we marked it read -> refresh count/list
        }
    }

    // ---------- cleanup: sweep read mail out of the inbox ----------
    property bool cleaning: false
    function cleanup() {
        if (root.cleaning) return
        root.cleaning = true
        cleanupProc.connectedSources = ["python3 $HOME/.config/proton-imap/sweep.py --apply # " + Date.now()]
        // Start reconcile polling NOW — do not depend on the process callback firing.
        cleanupReconcile.n = 0
        cleanupReconcile.start()
    }
    Plasma5Support.DataSource {
        id: cleanupProc; engine: "executable"; connectedSources: []
        onNewData: function (src, data) {
            disconnectSource(src)
            root.cleaning = false        // sweep finished -> stop the spinner now
            unreadSrc.poll(); listSrc.poll()
        }
    }
    // keep polling a few more seconds after the sweep (IMAP move + Bridge lag); also a
    // fallback to clear the spinner if the process callback never fires.
    Timer {
        id: cleanupReconcile; interval: 1500; repeat: true; property int n: 0
        onTriggered: {
            unreadSrc.poll(); listSrc.poll()
            n++
            if (n >= 5) { stop(); n = 0; root.cleaning = false }
        }
    }

    // ---------- helpers ----------
    function dateKey(d) { return Qt.formatDate(d, "yyyy-MM-dd") }
    function eventsForDate(d) { return root.eventsByDate[dateKey(d)] || [] }
    function timedEvents(d) { return eventsForDate(d).filter(e => !e.allDay) }
    function allDayEvents(d) { return eventsForDate(d).filter(e => e.allDay) }
    function hasEventsForDate(d) { return eventsForDate(d).length > 0 }
    function timeStr(d) { return Qt.formatTime(d, "HH:mm") }
    function evMin(d) { return d.getHours() * 60 + d.getMinutes() }
    function isToday(d) { return d.toDateString() === new Date().toDateString() }

    function senderName(from) {
        if (!from) return "(unknown)"
        from = ("" + from).trim()
        const q = from.match(/^"?([^"<]+?)"?\s*<[^>]+>/)   // display name before <addr>
        if (q && q[1].trim()) return q[1].trim()
        const m = from.match(/<([^>]+)>/)                   // <addr> -> full address
        if (m) return m[1].trim()
        return from                                          // bare addr -> full, keep domain
    }
    function senderDomain(from) {
        const m = ("" + from).match(/@([a-zA-Z0-9.-]+)/)
        return m ? m[1].toLowerCase().replace(/\.$/, "") : ""
    }
    function avatarUrl(from) {
        const d = senderDomain(from)
        return d ? "https://icons.duckduckgo.com/ip3/" + d + ".ico" : ""
    }
    function relTime(rfc) {
        const t = Date.parse(rfc); if (isNaN(t)) return ""
        const diff = (Date.now() - t) / 1000
        if (diff < 60) return "now"; if (diff < 3600) return Math.floor(diff / 60) + "m"
        if (diff < 86400) return Math.floor(diff / 3600) + "h"; if (diff < 604800) return Math.floor(diff / 86400) + "d"
        return Qt.formatDate(new Date(t), "MMM d")
    }
    function openMail(url) { if (url && url.length) Qt.openUrlExternally(url) }
    function weekStartJs() { return Qt.locale().firstDayOfWeek % 7 }
    function startOfWeek(d) { const x = new Date(d); x.setDate(x.getDate() - ((x.getDay() - weekStartJs() + 7) % 7)); x.setHours(0,0,0,0); return x }

    // human "in 2h 15m" / "25m ago" relative to the next/current event
    function nextEventLabel(d) {
        if (!isToday(d)) return ""
        const evs = timedEvents(d).slice().sort((a, b) => a.start - b.start)
        for (let i = 0; i < evs.length; ++i) {
            const s = evMin(evs[i].start), e = evMin(evs[i].end)
            if (root.nowMinutes < s) {
                const m = s - root.nowMinutes
                return "Next: " + evs[i].title + " in " + (m >= 60 ? Math.floor(m/60) + "h " + (m%60) + "m" : m + "m")
            }
            if (root.nowMinutes >= s && root.nowMinutes <= e) return "Now: " + evs[i].title
        }
        return evs.length ? "No more events today" : ""
    }

    // next events across all loaded days (ongoing + future), chronological
    function upcomingEvents(limit) {
        const now = new Date(); let out = []
        for (const k in root.eventsByDate) {
            const arr = root.eventsByDate[k]
            for (let i = 0; i < arr.length; ++i) if (arr[i].end >= now) out.push(arr[i])
        }
        out.sort((a, b) => a.start - b.start)
        return out.slice(0, limit)
    }

    // theme helpers (track matugen color scheme)
    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property color txt: Kirigami.Theme.textColor
    readonly property color nowColor: Kirigami.Theme.negativeTextColor
    function dim(a) { return Qt.rgba(txt.r, txt.g, txt.b, a) }
    function acc(a) { return Qt.rgba(accent.r, accent.g, accent.b, a) }
    readonly property color cardColor: Qt.rgba(txt.r, txt.g, txt.b, 0.04)
    readonly property color cardBorder: Qt.rgba(txt.r, txt.g, txt.b, 0.08)

    // ---------- panel element (replaces the digital clock) ----------
    //  Date · Time · ongoing event · unread mail count
    compactRepresentation: MouseArea {
        id: compact
        anchors.fill: parent                 // whole element is the click target
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // capture state on press so a click reliably toggles (avoids popup-dismiss race)
        property bool wasExpanded: false
        onPressed: wasExpanded = root.expanded
        onClicked: root.expanded = !wasExpanded

        readonly property string evText: root.panelEventText()
        readonly property bool evOngoing: root.panelEventOngoing()
        readonly property bool hasRight: evText !== ""
        readonly property real halfW: Math.max(leftGroup.implicitWidth, rightGroup.implicitWidth)
        readonly property real gap: Kirigami.Units.largeSpacing
        readonly property real divH: Math.min(height * 0.5, Kirigami.Units.gridUnit * 1.3)

        // Local x of the screen's horizontal PIXEL centre. The divider is pinned
        // here so it always marks dead-centre of the screen, regardless of where
        // the panel places this widget or how wide the content is.
        property real cx: width / 2
        function recenter() {
            var g = mapToGlobal(0, 0);
            if (g) compact.cx = (Screen.virtualX + Screen.width / 2) - g.x;
        }
        onXChanged: recenter()
        onWidthChanged: recenter()
        Component.onCompleted: recenter()
        Connections {
            target: Screen
            function onVirtualXChanged() { compact.recenter() }
            function onWidthChanged() { compact.recenter() }
        }
        // panel reflows (neighbours resizing) don't always emit xChanged here;
        // a low-frequency poll keeps the divider locked on screen-centre.
        Timer { interval: 400; running: true; repeat: true; onTriggered: compact.recenter() }

        // Width spans from the widget's left edge to just past the right content,
        // so screen-centre always falls inside the widget bounds.
        Layout.minimumWidth: Math.max(1, compact.cx
            + (compact.hasRight ? compact.gap + compact.halfW : Math.ceil(leftGroup.implicitWidth / 2))
            + Kirigami.Units.smallSpacing)
        Layout.preferredWidth: Layout.minimumWidth
        Layout.fillHeight: true

        // hover highlight over the content band only (not the empty left reserve)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            x: compact.hasRight ? (compact.cx - compact.gap - compact.halfW - Kirigami.Units.smallSpacing)
                                : (compact.cx - leftGroup.implicitWidth / 2 - Kirigami.Units.smallSpacing)
            width: compact.hasRight ? (2 * (compact.halfW + compact.gap) + Kirigami.Units.smallSpacing * 2)
                                    : (leftGroup.implicitWidth + Kirigami.Units.smallSpacing * 2)
            radius: Kirigami.Units.cornerRadius
            color: root.acc(0.12)
            visible: compact.containsMouse
        }

        // CENTER divider — pinned to the screen's pixel-centre
        Rectangle {
            visible: compact.hasRight
            x: Math.round(compact.cx) - Math.floor(width / 2)
            width: 1
            height: compact.divH
            anchors.verticalCenter: parent.verticalCenter
            radius: 0.5
            color: root.dim(0.3)
        }

        // LEFT group — mail + date + time. Right edge hugs the divider (centred on
        // it when there's no event).
        RowLayout {
            id: leftGroup
            anchors.verticalCenter: parent.verticalCenter
            x: compact.hasRight ? (compact.cx - compact.gap - leftGroup.implicitWidth)
                                : (compact.cx - leftGroup.implicitWidth / 2)
            spacing: Kirigami.Units.smallSpacing
            RowLayout {
                spacing: Math.round(Kirigami.Units.smallSpacing / 2)
                visible: root.unread > 0
                Kirigami.Icon { source: "mail-unread"; color: root.accent
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small; Layout.preferredHeight: Kirigami.Units.iconSizes.small }
                PlasmaComponents.Label { text: root.unread > 99 ? "99+" : root.unread
                    color: root.accent; font.weight: Font.Bold; font.pointSize: Kirigami.Theme.smallFont.pointSize }
            }
            PlasmaComponents.Label {
                text: root.clock.toLocaleDateString(Qt.locale(), "ddd d MMM")
                opacity: 0.85; font.weight: Font.Medium; font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
            PlasmaComponents.Label {
                text: Qt.formatTime(root.clock, "HH:mm")
                font.weight: Font.Bold; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2
            }
        }

        // RIGHT group — event. Left edge hugs the divider.
        RowLayout {
            id: rightGroup
            visible: compact.hasRight
            anchors.verticalCenter: parent.verticalCenter
            x: compact.cx + compact.gap
            spacing: Math.round(Kirigami.Units.smallSpacing / 2)
            Kirigami.Icon {
                source: compact.evOngoing ? "media-playback-start" : "view-calendar-day"
                color: compact.evOngoing ? root.accent : root.txt
                Layout.preferredWidth: Kirigami.Units.iconSizes.small; Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }
            PlasmaComponents.Label {
                text: compact.evText
                color: compact.evOngoing ? root.accent : root.txt
                opacity: compact.evOngoing ? 1 : 0.85
                font.weight: compact.evOngoing ? Font.Medium : Font.Normal
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                elide: Text.ElideRight; Layout.maximumWidth: Kirigami.Units.gridUnit * 9
            }
        }
    }

    // ---------- popup ----------
    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 58
        Layout.preferredHeight: Kirigami.Units.gridUnit * 36
        Layout.minimumWidth: Kirigami.Units.gridUnit * 46
        Layout.minimumHeight: Kirigami.Units.gridUnit * 32

        Component.onCompleted: { root.tickNow(); root.refreshAll() }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            // ===================== LEFT: EMAIL =====================
            ColumnLayout {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 18
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    Kirigami.Icon {
                        source: (!root.mailErrored && root.unread > 0) ? "mail-unread" : "mail-message"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                        color: root.unread > 0 ? root.accent : root.txt
                    }
                    PlasmaComponents.Label { text: "Inbox"; font.weight: Font.Bold; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1 }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        visible: root.unread > 0; radius: height / 2; color: root.accent
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                        Layout.preferredWidth: Math.max(height, badgeTxt.implicitWidth + Kirigami.Units.smallSpacing * 2)
                        PlasmaComponents.Label { id: badgeTxt; anchors.centerIn: parent; text: root.unread > 99 ? "99+" : root.unread
                            color: Kirigami.Theme.highlightedTextColor; font.weight: Font.Bold; font.pointSize: Kirigami.Theme.smallFont.pointSize }
                    }
                    PlasmaComponents.ToolButton {
                        icon.name: "edit-clear-history"; display: PlasmaComponents.AbstractButton.IconOnly
                        enabled: !root.cleaning
                        PlasmaComponents.ToolTip.text: "Clear read mail (sort out of inbox)"; PlasmaComponents.ToolTip.visible: hovered
                        onClicked: root.cleanup()
                        BusyIndicator { anchors.centerIn: parent; running: root.cleaning; visible: root.cleaning
                            implicitWidth: Kirigami.Units.iconSizes.small; implicitHeight: Kirigami.Units.iconSizes.small }
                    }
                    PlasmaComponents.ToolButton {
                        icon.name: "view-refresh"; display: PlasmaComponents.AbstractButton.IconOnly
                        PlasmaComponents.ToolTip.text: "Refresh"; PlasmaComponents.ToolTip.visible: hovered
                        onClicked: root.refreshAll()
                    }
                }

                // Inbox list (upper) — sized to its content (no empty space); Upcoming fills the rest
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: root.messages.length === 0
                        ? Kirigami.Units.gridUnit * 4
                        : Math.min(root.messages.length, 5) * (Kirigami.Units.gridUnit * 3.4 + 2) + Kirigami.Units.smallSpacing * 2
                    radius: Kirigami.Units.cornerRadius; color: root.cardColor
                    border.color: root.cardBorder; border.width: 1

                    ListView {
                        id: mailList
                        anchors.fill: parent; anchors.margins: Kirigami.Units.smallSpacing
                        clip: true; spacing: 2; model: root.messages
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {}
                        delegate: Rectangle {
                            width: mailList.width; height: Kirigami.Units.gridUnit * 3.4
                            radius: Kirigami.Units.cornerRadius
                            color: mArea.containsMouse ? root.acc(0.13) : "transparent"
                            // unread accent bar at the very left
                            Rectangle {
                                width: 3; height: parent.height - 12; radius: 1.5
                                anchors.left: parent.left; anchors.leftMargin: 2; anchors.verticalCenter: parent.verticalCenter
                                color: root.accent; visible: modelData.unread
                            }
                            // sender avatar — domain favicon, falls back to initial
                            Rectangle {
                                id: av
                                anchors.left: parent.left; anchors.leftMargin: Kirigami.Units.smallSpacing + 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: Kirigami.Units.gridUnit * 2; height: width
                                radius: Kirigami.Units.cornerRadius; clip: true
                                color: root.acc(0.18)
                                Image {
                                    id: favimg; anchors.fill: parent; anchors.margins: 3
                                    source: root.avatarUrl(modelData.from)
                                    fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
                                    sourceSize.width: 48; sourceSize.height: 48
                                    visible: status === Image.Ready
                                }
                                PlasmaComponents.Label {
                                    anchors.centerIn: parent; visible: favimg.status !== Image.Ready
                                    text: ((root.senderName(modelData.from) || "?").charAt(0) || "?").toUpperCase()
                                    color: root.accent; font.weight: Font.Bold
                                }
                            }
                            ColumnLayout {
                                anchors.left: av.right; anchors.right: tLabel.left; anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Kirigami.Units.smallSpacing + 2; anchors.rightMargin: Kirigami.Units.smallSpacing; spacing: 0
                                PlasmaComponents.Label { text: root.senderName(modelData.from)
                                    font.weight: modelData.unread ? Font.Bold : Font.Normal
                                    opacity: modelData.unread ? 1.0 : 0.6
                                    elide: Text.ElideRight; Layout.fillWidth: true }
                                PlasmaComponents.Label { text: modelData.subject || "(no subject)"
                                    opacity: modelData.unread ? 0.7 : 0.45
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize; elide: Text.ElideRight; Layout.fillWidth: true }
                            }
                            PlasmaComponents.Label { id: tLabel; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: Kirigami.Units.smallSpacing
                                text: root.relTime(modelData.date); opacity: modelData.unread ? 0.6 : 0.4; font.pointSize: Kirigami.Theme.smallFont.pointSize }
                            MouseArea { id: mArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.openReader(modelData.uid, modelData.web_url) }
                        }
                    }
                    PlasmaComponents.Label { anchors.centerIn: parent; visible: root.messages.length === 0
                        text: root.mailErrored ? "Bridge unreachable" : "Inbox zero ✓"; opacity: 0.5 }
                }

                // Upcoming header
                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.smallSpacing; spacing: Kirigami.Units.smallSpacing
                    Kirigami.Icon { source: "view-calendar-upcoming-days"
                        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium; Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium; color: root.accent }
                    PlasmaComponents.Label { text: "Upcoming"; font.weight: Font.Bold; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1 }
                }

                // Upcoming events (lower half) — fills remaining space
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    radius: Kirigami.Units.cornerRadius; color: root.cardColor
                    border.color: root.cardBorder; border.width: 1

                    ListView {
                        id: upList
                        anchors.fill: parent; anchors.margins: Kirigami.Units.smallSpacing
                        clip: true; spacing: 2; model: root.upcomingEvents(30)
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {}
                        delegate: Rectangle {
                            width: upList.width; height: Kirigami.Units.gridUnit * 2.8
                            radius: Kirigami.Units.cornerRadius
                            color: uArea.containsMouse ? root.acc(0.13) : "transparent"
                            Rectangle { width: 3; height: parent.height - 10; anchors.left: parent.left; anchors.leftMargin: 2
                                anchors.verticalCenter: parent.verticalCenter; radius: 1.5; color: root.accent
                                visible: root.isToday(modelData.start) || uArea.containsMouse }
                            ColumnLayout {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Kirigami.Units.smallSpacing + 4; anchors.rightMargin: Kirigami.Units.smallSpacing; spacing: 0
                                PlasmaComponents.Label { text: modelData.title; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                                PlasmaComponents.Label {
                                    text: (root.isToday(modelData.start) ? "Today" : Qt.formatDate(modelData.start, "ddd d MMM"))
                                          + (modelData.allDay ? "  ·  all day" : "  ·  " + root.timeStr(modelData.start))
                                    opacity: 0.6; font.pointSize: Kirigami.Theme.smallFont.pointSize; elide: Text.ElideRight; Layout.fillWidth: true }
                            }
                            MouseArea { id: uArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { root.selectedDate = modelData.start; root.displayDate = modelData.start } }
                        }
                    }
                    PlasmaComponents.Label { anchors.centerIn: parent; visible: upList.count === 0
                        text: root.calErrored ? "Calendar unavailable" : "Nothing upcoming"; opacity: 0.5 }
                }

                PlasmaComponents.Button { Layout.fillWidth: true; text: "Open Proton Mail"; icon.name: "proton-mail"; onClicked: exec.run("proton-mail") }
            }

            Kirigami.Separator { Layout.fillHeight: true }

            // ===================== RIGHT: CALENDAR =====================
            ColumnLayout {
                Layout.fillWidth: true; Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                // --- header: selected day (left) · month navigator (right) ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.largeSpacing
                    ColumnLayout {
                        spacing: 0
                        PlasmaComponents.Label { text: root.selectedDate.toLocaleDateString(Qt.locale(), "dddd")
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 8; font.weight: Font.Bold; color: root.accent }
                        PlasmaComponents.Label { text: root.selectedDate.toLocaleDateString(Qt.locale(), "d MMMM yyyy")
                            opacity: 0.6; font.pointSize: Kirigami.Theme.defaultFont.pointSize }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 0
                        PlasmaComponents.ToolButton { icon.name: "go-previous"; display: PlasmaComponents.AbstractButton.IconOnly
                            onClicked: { const d = new Date(root.displayDate); d.setMonth(d.getMonth()-1); root.displayDate = d; root.loadMonth() } }
                        PlasmaComponents.Label { text: root.displayDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                            font.weight: Font.Medium; horizontalAlignment: Text.AlignHCenter
                            Layout.minimumWidth: Kirigami.Units.gridUnit * 7 }
                        PlasmaComponents.ToolButton { icon.name: "go-next"; display: PlasmaComponents.AbstractButton.IconOnly
                            onClicked: { const d = new Date(root.displayDate); d.setMonth(d.getMonth()+1); root.displayDate = d; root.loadMonth() } }
                        PlasmaComponents.ToolButton { icon.name: "go-jump-today"; display: PlasmaComponents.AbstractButton.IconOnly
                            PlasmaComponents.ToolTip.text: "Jump to today"; PlasmaComponents.ToolTip.visible: hovered
                            onClicked: { const t = new Date(); root.displayDate = t; root.selectedDate = t; root.loadMonth() } }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true; spacing: 0
                    Repeater {
                        model: { const days = [], loc = Qt.locale(), qf = loc.firstDayOfWeek
                                 for (let i=0;i<7;++i) days.push(loc.dayName(((qf-1+i)%7)+1, Locale.ShortFormat)); return days }
                        PlasmaComponents.Label { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: modelData
                            opacity: 0.5; font.pointSize: Kirigami.Theme.smallFont.pointSize; font.weight: Font.Medium }
                    }
                }
                Grid {
                    id: grid
                    Layout.fillWidth: true; Layout.preferredHeight: Kirigami.Units.gridUnit * 9.5
                    columns: 7; rows: 6
                    readonly property real cw: width / 7
                    readonly property real ch: height / 6
                    readonly property date firstDay: root.startOfWeek(new Date(root.displayDate.getFullYear(), root.displayDate.getMonth(), 1))
                    Repeater {
                        model: 42
                        Item {
                            width: grid.cw; height: grid.ch
                            readonly property date dayDate: { const d = new Date(grid.firstDay); d.setDate(d.getDate()+index); return d }
                            readonly property bool isCur: dayDate.getMonth() === root.displayDate.getMonth()
                            readonly property bool isTd: dayDate.toDateString() === new Date().toDateString()
                            readonly property bool isSel: dayDate.toDateString() === root.selectedDate.toDateString()
                            Rectangle {
                                id: dayCircle
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: -3
                                width: Math.min(parent.width - 6, parent.height - 12, Kirigami.Units.gridUnit * 2); height: width; radius: width / 2
                                color: isSel ? root.accent : (isTd ? root.acc(0.18) : (cell.containsMouse ? root.acc(0.10) : "transparent"))
                                border.color: isTd && !isSel ? root.accent : "transparent"; border.width: 1
                                PlasmaComponents.Label { anchors.centerIn: parent; text: dayDate.getDate()
                                    color: isSel ? Kirigami.Theme.highlightedTextColor : (isTd ? root.accent : (isCur ? root.txt : root.dim(0.35)))
                                    font.bold: isTd || isSel; font.pointSize: Kirigami.Theme.smallFont.pointSize }
                            }
                            // event indicator dot BELOW the circle (never overlaps the number)
                            Rectangle {
                                anchors.top: dayCircle.bottom; anchors.topMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 5; height: 5; radius: 2.5
                                visible: root.hasEventsForDate(dayDate)
                                color: isSel ? root.accent : root.acc(0.85)
                            }
                            MouseArea { id: cell; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedDate = dayDate }
                        }
                    }
                }

                // --- all-day chips ---
                Flow {
                    Layout.fillWidth: true; spacing: Kirigami.Units.smallSpacing
                    visible: root.allDayEvents(root.selectedDate).length > 0
                    Repeater {
                        model: root.allDayEvents(root.selectedDate)
                        Rectangle {
                            radius: Kirigami.Units.cornerRadius; color: root.acc(0.15)
                            height: Kirigami.Units.gridUnit * 1.4; width: chipTxt.implicitWidth + Kirigami.Units.largeSpacing
                            PlasmaComponents.Label { id: chipTxt; anchors.centerIn: parent; text: modelData.title
                                color: root.accent; font.pointSize: Kirigami.Theme.smallFont.pointSize }
                        }
                    }
                }

                // --- status: event count (left) · now/next (right) ---
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    PlasmaComponents.Label {
                        text: { const n = root.eventsForDate(root.selectedDate).length
                                return n === 0 ? "No events" : (n === 1 ? "1 event" : n + " events") }
                        font.weight: Font.Medium; opacity: 0.75
                    }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        visible: text.length > 0
                        text: root.nextEventLabel(root.selectedDate)
                        color: root.accent; font.weight: Font.Medium
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        elide: Text.ElideRight; Layout.maximumWidth: Kirigami.Units.gridUnit * 18
                    }
                }

                // ===== DAY TIMELINE (fills remaining space) =====
                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    radius: Kirigami.Units.cornerRadius; color: root.cardColor
                    border.color: root.cardBorder; border.width: 1
                    clip: true

                    readonly property var evs: root.timedEvents(root.selectedDate).slice().sort((a,b)=>a.start-b.start)
                    // visible range [loMin, hiMin]
                    readonly property int loMin: {
                        let lo = 9*60, has = false
                        for (let i=0;i<evs.length;++i){ const s=root.evMin(evs[i].start); lo = has?Math.min(lo,s):s; has=true }
                        if (root.isToday(root.selectedDate)) lo = has ? Math.min(lo, root.nowMinutes) : root.nowMinutes
                        else if (!has) lo = 8*60
                        return Math.max(0, Math.floor(lo/60)*60 - 60)
                    }
                    readonly property int hiMin: {
                        let hi = 18*60, has = false
                        for (let i=0;i<evs.length;++i){ const e=root.evMin(evs[i].end); hi = has?Math.max(hi,e):e; has=true }
                        if (root.isToday(root.selectedDate)) hi = has ? Math.max(hi, root.nowMinutes) : root.nowMinutes+180
                        else if (!has) hi = 20*60
                        let v = Math.min(1440, Math.ceil(hi/60)*60 + 60)
                        return Math.max(v, loMin + 240)
                    }
                    readonly property real pxPerMin: (Kirigami.Units.gridUnit * 3) / 60
                    readonly property real gutter: Kirigami.Units.gridUnit * 2.6
                    function yAt(min) { return (min - loMin) * pxPerMin }

                    PlasmaComponents.Label {
                        anchors.centerIn: parent
                        visible: parent.evs.length === 0
                        text: root.calErrored ? "Calendar unavailable" : "Nothing scheduled"
                        opacity: 0.45
                    }

                    Flickable {
                        id: tl
                        anchors.fill: parent; anchors.margins: Kirigami.Units.smallSpacing
                        visible: parent.evs.length > 0
                        clip: true
                        contentWidth: width
                        contentHeight: parent.yAt(parent.hiMin)
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {}

                        property var tlb: parent   // timeline box (for range/funcs)

                        Component.onCompleted: {
                            // center on "now" if today, else top
                            if (root.isToday(root.selectedDate)) {
                                const yy = tlb.yAt(root.nowMinutes) - height / 2
                                contentY = Math.max(0, Math.min(yy, contentHeight - height))
                            }
                        }

                        // hour lines + labels
                        Repeater {
                            model: Math.floor(tl.tlb.hiMin/60) - Math.ceil(tl.tlb.loMin/60) + 1
                            Item {
                                readonly property int hour: Math.ceil(tl.tlb.loMin/60) + index
                                width: tl.width
                                y: tl.tlb.yAt(hour*60)
                                height: 1
                                PlasmaComponents.Label {
                                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                    width: tl.tlb.gutter - Kirigami.Units.smallSpacing
                                    horizontalAlignment: Text.AlignRight
                                    text: ("0"+hour).slice(-2) + ":00"
                                    opacity: 0.4; font.pointSize: Kirigami.Theme.smallFont.pointSize
                                }
                                Rectangle { anchors.left: parent.left; anchors.leftMargin: tl.tlb.gutter; anchors.right: parent.right
                                    height: 1; color: root.dim(0.07) }
                            }
                        }

                        // event blocks
                        Repeater {
                            model: tl.tlb.evs
                            Rectangle {
                                readonly property int sMin: root.evMin(modelData.start)
                                readonly property int eMin: root.evMin(modelData.end)
                                readonly property bool ongoing: root.isToday(root.selectedDate) && root.nowMinutes >= sMin && root.nowMinutes <= eMin
                                x: tl.tlb.gutter + Kirigami.Units.smallSpacing
                                y: tl.tlb.yAt(sMin)
                                width: tl.width - x - Kirigami.Units.smallSpacing
                                height: Math.max(Kirigami.Units.gridUnit * 1.8, tl.tlb.yAt(eMin) - tl.tlb.yAt(sMin) - 2)
                                radius: Kirigami.Units.cornerRadius
                                color: ongoing ? root.acc(0.28) : root.acc(0.14)
                                border.color: ongoing ? root.accent : root.acc(0.3); border.width: ongoing ? 2 : 1
                                Rectangle { width: 3; height: parent.height - 8; anchors.left: parent.left; anchors.leftMargin: 3
                                    anchors.verticalCenter: parent.verticalCenter; radius: 1.5; color: root.accent }
                                ColumnLayout {
                                    anchors.fill: parent; anchors.leftMargin: Kirigami.Units.smallSpacing + 6
                                    anchors.rightMargin: Kirigami.Units.smallSpacing; anchors.topMargin: 3; anchors.bottomMargin: 3; spacing: 0
                                    PlasmaComponents.Label { text: modelData.title; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                                    PlasmaComponents.Label { text: root.timeStr(modelData.start) + " – " + root.timeStr(modelData.end)
                                        + (modelData.location ? "  ·  " + modelData.location : "")
                                        opacity: 0.7; font.pointSize: Kirigami.Theme.smallFont.pointSize; elide: Text.ElideRight; Layout.fillWidth: true
                                        visible: parent.height > Kirigami.Units.gridUnit * 2 }
                                }
                            }
                        }

                        // NOW line — opaque time pill in the gutter + line across
                        Item {
                            visible: root.isToday(root.selectedDate) && root.nowMinutes >= tl.tlb.loMin && root.nowMinutes <= tl.tlb.hiMin
                            width: tl.width; y: tl.tlb.yAt(root.nowMinutes); height: 1; z: 20
                            Rectangle { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: tl.tlb.gutter
                                anchors.right: parent.right; height: 2; radius: 1; color: root.nowColor }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left
                                width: tl.tlb.gutter - 3; height: Kirigami.Units.gridUnit * 1.15; radius: height / 2
                                color: root.nowColor
                                PlasmaComponents.Label {
                                    anchors.centerIn: parent
                                    text: ("0"+Math.floor(root.nowMinutes/60)).slice(-2) + ":" + ("0"+(root.nowMinutes%60)).slice(-2)
                                    color: Kirigami.Theme.highlightedTextColor; font.bold: true
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                }
                            }
                        }
                    }
                }
            }
        }

        // ===== EMAIL READER — modal card floating above the popup =====
        Item {
            anchors.fill: parent
            z: 100
            visible: root.readingMail !== null || root.readerLoading

            // scrim: dims the widget behind, click outside to dismiss
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.45)
                MouseArea { anchors.fill: parent; onClicked: root.closeReader() }
            }

            // floating card, inset from the popup edges so it reads as "above"
            Rectangle {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.gridUnit * 1.75
                radius: Kirigami.Units.cornerRadius * 1.5
                color: Kirigami.Theme.backgroundColor
                border.color: root.acc(0.35); border.width: 1
                MouseArea { anchors.fill: parent }   // swallow clicks (don't dismiss)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.smallSpacing
                    visible: root.readingMail !== null

                    RowLayout {
                        Layout.fillWidth: true; spacing: Kirigami.Units.smallSpacing
                        PlasmaComponents.ToolButton { icon.name: "go-previous"; text: "Back"
                            display: PlasmaComponents.AbstractButton.TextBesideIcon; onClicked: root.closeReader() }
                        Item { Layout.fillWidth: true }
                        Kirigami.Icon { source: "checkmark"; color: root.accent
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small; Layout.preferredHeight: Kirigami.Units.iconSizes.small }
                        PlasmaComponents.Label { text: "Read"; opacity: 0.55; font.pointSize: Kirigami.Theme.smallFont.pointSize }
                        PlasmaComponents.ToolButton { icon.name: "internet-web-browser"; display: PlasmaComponents.AbstractButton.IconOnly
                            PlasmaComponents.ToolTip.text: "Open in Proton web"; PlasmaComponents.ToolTip.visible: hovered
                            enabled: root.readingUrl.length > 0; onClicked: root.openMail(root.readingUrl) }
                    }

                    RowLayout {
                        Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.smallSpacing; spacing: Kirigami.Units.smallSpacing
                        Rectangle {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.large; Layout.preferredHeight: Kirigami.Units.iconSizes.large
                            radius: Kirigami.Units.cornerRadius; clip: true; color: root.acc(0.22)
                            Image {
                                id: readerFav; anchors.fill: parent; anchors.margins: 4
                                source: root.readingMail ? root.avatarUrl(root.readingMail.from) : ""
                                fillMode: Image.PreserveAspectFit; smooth: true; asynchronous: true
                                sourceSize.width: 64; sourceSize.height: 64
                                visible: status === Image.Ready
                            }
                            PlasmaComponents.Label { anchors.centerIn: parent; visible: readerFav.status !== Image.Ready
                                text: ((root.readingMail ? root.senderName(root.readingMail.from) : "") || "?").charAt(0).toUpperCase()
                                color: root.accent; font.weight: Font.Bold; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2 }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0
                            PlasmaComponents.Label { Layout.fillWidth: true
                                text: root.readingMail ? root.senderName(root.readingMail.from) : ""
                                font.weight: Font.Bold; elide: Text.ElideRight }
                            PlasmaComponents.Label { Layout.fillWidth: true
                                text: root.readingMail ? root.readingMail.date : ""
                                opacity: 0.55; font.pointSize: Kirigami.Theme.smallFont.pointSize; elide: Text.ElideRight }
                        }
                    }

                    PlasmaComponents.Label {
                        Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.smallSpacing
                        text: root.readingMail ? (root.readingMail.subject || "(no subject)") : ""
                        font.weight: Font.Bold; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 3; wrapMode: Text.Wrap
                    }
                    Kirigami.Separator { Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.smallSpacing }

                    Flickable {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.topMargin: Kirigami.Units.smallSpacing
                        clip: true; contentWidth: width; contentHeight: bodyLabel.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {}
                        PlasmaComponents.Label {
                            id: bodyLabel
                            width: parent.width - Kirigami.Units.largeSpacing
                            text: root.readingMail ? (root.readingMail.body || "") : ""
                            wrapMode: Text.Wrap; textFormat: Text.PlainText; opacity: 0.85; lineHeight: 1.15
                        }
                    }
                }
                BusyIndicator { anchors.centerIn: parent; running: root.readerLoading; visible: root.readerLoading }
            }
        }
    }
}
