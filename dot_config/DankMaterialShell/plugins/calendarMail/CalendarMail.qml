import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Proton Calendar + Mail bar widget.
//   Calendar events  -> `pcal` (Proton "Share with anyone" ICS feed)
//   Unread + inbox    -> `pmail` (Bridge IMAP)
// Bar pill shows an unread badge; click opens a popout with a month/week/day
// calendar and a clickable unread-inbox shortlist (opens in Proton web).
PluginComponent {
    id: root

    // ---- state ----
    property int unread: -1
    property bool mailErrored: false
    property var messages: []
    property var eventsByDate: ({})        // "yyyy-MM-dd" -> [event]
    property bool calErrored: false

    property int refreshSeconds: pluginData.refreshSeconds || 120
    property int listLimit: pluginData.listLimit || 8

    // popout view state
    property string viewMode: "month"      // month | week | day
    property var displayDate: new Date()
    property var selectedDate: new Date()

    popoutWidth: 460
    popoutHeight: 640

    readonly property string pillIcon: (!mailErrored && unread > 0) ? "mark_email_unread" : "calendar_month"
    readonly property color pillColor: mailErrored ? Theme.error
                                                    : (unread > 0 ? Theme.primary : Theme.surfaceText)

    // ---------- data refresh ----------
    Component.onCompleted: {
        Qt.callLater(refreshAll)
    }

    Timer {
        interval: root.refreshSeconds * 1000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: root.refreshMail()
    }

    function refreshAll() {
        refreshMail()
        loadMonth()
    }

    function refreshMail() {
        if (!unreadProc.running)
            unreadProc.running = true
        if (!listProc.running)
            listProc.running = true
    }

    Process {
        id: unreadProc
        command: ["sh", "-c", "$HOME/.local/bin/pmail unread"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim())
                if (!isNaN(n)) {
                    root.unread = n
                    root.mailErrored = false
                } else {
                    root.mailErrored = true
                }
            }
        }
        onExited: code => { if (code !== 0) root.mailErrored = true }
    }

    Process {
        id: listProc
        command: ["sh", "-c", "$HOME/.local/bin/pmail list INBOX --unread --limit " + root.listLimit]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.messages = JSON.parse(text)
                } catch (e) {
                    root.messages = []
                }
            }
        }
    }

    function loadMonth() {
        const ym = root.displayDate.getFullYear() + "-"
                 + ("0" + (root.displayDate.getMonth() + 1)).slice(-2)
        calProc.command = ["sh", "-c", "$HOME/.local/bin/pcal month " + ym]
        if (!calProc.running)
            calProc.running = true
    }

    Process {
        id: calProc
        command: ["sh", "-c", "true"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const evs = JSON.parse(text)
                    const map = {}
                    for (let i = 0; i < evs.length; ++i) {
                        const e = evs[i]
                        const key = (e.start || "").slice(0, 10)
                        if (!key)
                            continue
                        if (!map[key])
                            map[key] = []
                        map[key].push({
                            "title": e.title || "(no title)",
                            "start": new Date(e.start),
                            "end": e.end ? new Date(e.end) : new Date(e.start),
                            "allDay": !!e.allDay,
                            "location": e.location || "",
                            "calendar": e.calendar || ""
                        })
                    }
                    root.eventsByDate = map
                    root.calErrored = false
                } catch (e) {
                    root.calErrored = true
                }
            }
        }
        onExited: code => { if (code !== 0) root.calErrored = true }
    }

    // ---------- helpers ----------
    function dateKey(d) { return Qt.formatDate(d, "yyyy-MM-dd") }
    function eventsForDate(d) { return root.eventsByDate[dateKey(d)] || [] }
    function hasEventsForDate(d) { return eventsForDate(d).length > 0 }

    function senderName(from) {
        if (!from)
            return "(unknown)"
        const q = from.match(/"([^"]+)"/)
        if (q)
            return q[1]
        const lt = from.indexOf("<")
        if (lt > 0)
            return from.slice(0, lt).trim()
        const at = from.indexOf("@")
        return at > 0 ? from.slice(0, at).replace(/[<]/g, "").trim() : from
    }

    function relTime(rfc) {
        const t = Date.parse(rfc)
        if (isNaN(t))
            return ""
        const diff = (Date.now() - t) / 1000
        if (diff < 60) return "now"
        if (diff < 3600) return Math.floor(diff / 60) + "m"
        if (diff < 86400) return Math.floor(diff / 3600) + "h"
        if (diff < 604800) return Math.floor(diff / 86400) + "d"
        return Qt.formatDate(new Date(t), "MMM d")
    }

    function timeStr(d) { return Qt.formatTime(d, "HH:mm") }

    function openMail(url) {
        if (url && url.length > 0)
            Qt.openUrlExternally(url)
    }

    // weekday-aligned start of week (locale aware)
    function weekStartJs() { return Qt.locale().firstDayOfWeek % 7 }
    function startOfWeek(d) {
        const x = new Date(d)
        const diff = (x.getDay() - weekStartJs() + 7) % 7
        x.setDate(x.getDate() - diff)
        x.setHours(0, 0, 0, 0)
        return x
    }

    // events across a [from,to) day range, flattened + sorted (for week/day agenda)
    function eventsInRange(fromDate, days) {
        let out = []
        for (let i = 0; i < days; ++i) {
            const d = new Date(fromDate)
            d.setDate(d.getDate() + i)
            out = out.concat(eventsForDate(d))
        }
        out.sort((a, b) => a.start.getTime() - b.start.getTime())
        return out
    }

    pillClickAction: null   // null -> BasePill auto-toggles the popout (hasPopout)

    // ---------- bar pills ----------
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            DankIcon {
                name: root.pillIcon
                size: Theme.iconSize - 6
                color: root.pillColor
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: root.unread > 0 ? (root.unread > 99 ? "99+" : root.unread.toString()) : ""
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: root.pillColor
                anchors.verticalCenter: parent.verticalCenter
                visible: root.unread > 0
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS
            DankIcon {
                name: root.pillIcon
                size: Theme.iconSize - 6
                color: root.pillColor
                anchors.horizontalCenter: parent.horizontalCenter
            }
            StyledText {
                text: root.unread > 0 ? (root.unread > 99 ? "99+" : root.unread.toString()) : ""
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: root.pillColor
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.unread > 0
            }
        }
    }

    // ---------- popout ----------
    popoutContent: Component {
        Item {
            id: panel
            anchors.fill: parent

            Component.onCompleted: root.refreshAll()

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingM

                // ===== MAIL =====
                Row {
                    width: parent.width
                    height: 28
                    spacing: Theme.spacingS
                    DankIcon {
                        name: "mail"
                        size: 18
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: root.mailErrored ? "Bridge unreachable"
                                               : (root.unread === 1 ? "1 unread" : root.unread + " unread")
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item { width: parent.width - 18 - 2 * Theme.spacingS - refreshBtn.width - 120; height: 1 }
                    Rectangle {
                        id: refreshBtn
                        width: 28; height: 28; radius: Theme.cornerRadius
                        color: refreshArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.12) : "transparent"
                        anchors.verticalCenter: parent.verticalCenter
                        DankIcon { anchors.centerIn: parent; name: "refresh"; size: 16; color: Theme.primary }
                        MouseArea {
                            id: refreshArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.refreshAll()
                        }
                    }
                }

                DankListView {
                    width: parent.width
                    height: 184
                    clip: true
                    spacing: Theme.spacingXS
                    model: root.messages

                    delegate: Rectangle {
                        width: parent ? parent.width : 0
                        height: 48
                        radius: Theme.cornerRadius
                        color: mailArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.10) : Theme.nestedSurface
                        border.color: mailArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.3) : Theme.outlineMedium
                        border.width: 1

                        Column {
                            anchors.left: parent.left
                            anchors.right: timeLabel.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Theme.spacingM
                            anchors.rightMargin: Theme.spacingS
                            spacing: 2
                            StyledText {
                                width: parent.width
                                text: root.senderName(modelData.from)
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                            StyledText {
                                width: parent.width
                                text: modelData.subject || "(no subject)"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.withAlpha(Theme.surfaceText, 0.7)
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        StyledText {
                            id: timeLabel
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.rightMargin: Theme.spacingM
                            anchors.topMargin: Theme.spacingS
                            text: root.relTime(modelData.date)
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.withAlpha(Theme.surfaceText, 0.5)
                        }

                        MouseArea {
                            id: mailArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openMail(modelData.web_url)
                        }
                    }
                }

                StyledText {
                    width: parent.width
                    visible: root.messages.length === 0
                    text: root.mailErrored ? "Could not reach Proton Bridge" : "Inbox zero ✓"
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.withAlpha(Theme.surfaceText, 0.6)
                }

                Rectangle {
                    width: parent.width; height: 1
                    color: Theme.outlineMedium
                }

                // ===== CALENDAR =====
                Row {
                    width: parent.width
                    height: 30
                    spacing: Theme.spacingXS
                    Repeater {
                        model: [{ "m": "month", "t": "Month" }, { "m": "week", "t": "Week" }, { "m": "day", "t": "Day" }]
                        Rectangle {
                            width: (parent.width - 2 * Theme.spacingXS) / 3
                            height: 30
                            radius: Theme.cornerRadius
                            color: root.viewMode === modelData.m ? Theme.withAlpha(Theme.primary, 0.18)
                                                                 : (segArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.08) : "transparent")
                            StyledText {
                                anchors.centerIn: parent
                                text: modelData.t
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: root.viewMode === modelData.m ? Font.Medium : Font.Normal
                                color: root.viewMode === modelData.m ? Theme.primary : Theme.surfaceText
                            }
                            MouseArea {
                                id: segArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.viewMode = modelData.m
                            }
                        }
                    }
                }

                // month nav (visible in month view)
                Row {
                    width: parent.width
                    height: 28
                    visible: root.viewMode === "month"
                    Rectangle {
                        width: 28; height: 28; radius: Theme.cornerRadius
                        color: prevArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.12) : "transparent"
                        DankIcon { anchors.centerIn: parent; name: "chevron_left"; size: 14; color: Theme.primary }
                        MouseArea {
                            id: prevArea
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const d = new Date(root.displayDate)
                                d.setMonth(d.getMonth() - 1)
                                root.displayDate = d
                                root.loadMonth()
                            }
                        }
                    }
                    StyledText {
                        width: parent.width - 56
                        height: 28
                        text: root.displayDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    Rectangle {
                        width: 28; height: 28; radius: Theme.cornerRadius
                        color: nextArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.12) : "transparent"
                        DankIcon { anchors.centerIn: parent; name: "chevron_right"; size: 14; color: Theme.primary }
                        MouseArea {
                            id: nextArea
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const d = new Date(root.displayDate)
                                d.setMonth(d.getMonth() + 1)
                                root.displayDate = d
                                root.loadMonth()
                            }
                        }
                    }
                }

                // weekday header (month view)
                Row {
                    width: parent.width
                    height: 16
                    visible: root.viewMode === "month"
                    Repeater {
                        model: {
                            const days = []
                            const loc = Qt.locale()
                            const qtFirst = loc.firstDayOfWeek
                            for (let i = 0; i < 7; ++i) {
                                const qtDay = ((qtFirst - 1 + i) % 7) + 1
                                days.push(loc.dayName(qtDay, Locale.ShortFormat))
                            }
                            return days
                        }
                        Item {
                            width: parent.width / 7
                            height: 16
                            StyledText {
                                anchors.centerIn: parent
                                text: modelData
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.withAlpha(Theme.surfaceText, 0.6)
                            }
                        }
                    }
                }

                // month grid
                Grid {
                    id: monthGrid
                    visible: root.viewMode === "month"
                    width: parent.width
                    height: 210
                    columns: 7
                    rows: 6
                    readonly property date firstDay: {
                        const f = new Date(root.displayDate.getFullYear(), root.displayDate.getMonth(), 1)
                        return root.startOfWeek(f)
                    }
                    Repeater {
                        model: 42
                        Item {
                            width: monthGrid.width / 7
                            height: monthGrid.height / 6
                            readonly property date dayDate: {
                                const d = new Date(monthGrid.firstDay)
                                d.setDate(d.getDate() + index)
                                return d
                            }
                            readonly property bool isCurMonth: dayDate.getMonth() === root.displayDate.getMonth()
                            readonly property bool isToday: dayDate.toDateString() === new Date().toDateString()
                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width - 4, parent.height - 4, 32)
                                height: width
                                radius: Theme.cornerRadius
                                color: isToday ? Theme.withAlpha(Theme.primary, 0.12)
                                               : (cellArea.containsMouse ? Theme.withAlpha(Theme.primary, 0.08) : "transparent")
                                StyledText {
                                    anchors.centerIn: parent
                                    text: dayDate.getDate()
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: isToday ? Font.Medium : Font.Normal
                                    color: isToday ? Theme.primary
                                                   : (isCurMonth ? Theme.surfaceText : Theme.withAlpha(Theme.surfaceText, 0.4))
                                }
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottomMargin: 3
                                    width: 12; height: 2; radius: 1
                                    visible: root.hasEventsForDate(dayDate)
                                    color: Theme.primary
                                    opacity: isToday ? 0.9 : 0.7
                                }
                            }
                            MouseArea {
                                id: cellArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedDate = dayDate
                                    root.viewMode = "day"
                                }
                            }
                        }
                    }
                }

                // week / day agenda
                Column {
                    width: parent.width
                    visible: root.viewMode !== "month"
                    spacing: Theme.spacingXS

                    StyledText {
                        width: parent.width
                        text: root.viewMode === "day"
                              ? root.selectedDate.toLocaleDateString(Qt.locale(), "dddd, MMMM d")
                              : ("Week of " + root.startOfWeek(root.selectedDate).toLocaleDateString(Qt.locale(), "MMMM d"))
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                        horizontalAlignment: Text.AlignHCenter
                    }

                    DankListView {
                        width: parent.width
                        height: 250
                        clip: true
                        spacing: Theme.spacingXS
                        model: root.viewMode === "day"
                               ? root.eventsForDate(root.selectedDate)
                               : root.eventsInRange(root.startOfWeek(root.selectedDate), 7)
                        delegate: Rectangle {
                            width: parent ? parent.width : 0
                            height: 46
                            radius: Theme.cornerRadius
                            color: Theme.nestedSurface
                            border.color: Theme.outlineMedium
                            border.width: 1
                            Rectangle {
                                width: 3; height: parent.height - 8
                                anchors.left: parent.left; anchors.leftMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 2; color: Theme.primary; opacity: 0.8
                            }
                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Theme.spacingM
                                anchors.rightMargin: Theme.spacingS
                                spacing: 2
                                StyledText {
                                    width: parent.width
                                    text: modelData.title
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                                StyledText {
                                    width: parent.width
                                    text: {
                                        let s = modelData.allDay ? "All day" : root.timeStr(modelData.start)
                                        if (root.viewMode === "week")
                                            s = Qt.formatDate(modelData.start, "ddd") + "  " + s
                                        if (modelData.location)
                                            s += "  ·  " + modelData.location
                                        return s
                                    }
                                    width: parent.width
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.withAlpha(Theme.surfaceText, 0.7)
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }
                        }
                    }
                    StyledText {
                        width: parent.width
                        visible: (root.viewMode === "day" ? root.eventsForDate(root.selectedDate).length
                                                          : root.eventsInRange(root.startOfWeek(root.selectedDate), 7).length) === 0
                        text: root.calErrored ? "Calendar unavailable" : "No events"
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.withAlpha(Theme.surfaceText, 0.6)
                    }
                }
            }
        }
    }
}
