import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "calendarMail"

    StyledText {
        width: parent.width
        text: "Proton Calendar & Mail"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Calendar pulls from a Proton 'Share with anyone → Full view' ICS link in ~/.config/proton-calendar/credentials. Mail uses the pmail CLI over Proton Bridge."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    SelectionSetting {
        settingKey: "refreshSeconds"
        label: "Mail refresh interval"
        description: "How often to re-check unread mail"
        options: [
            { label: "30 seconds", value: 30 },
            { label: "1 minute", value: 60 },
            { label: "2 minutes", value: 120 },
            { label: "5 minutes", value: 300 }
        ]
        defaultValue: 120
    }

    SelectionSetting {
        settingKey: "listLimit"
        label: "Inbox shortlist length"
        description: "Number of recent unread emails to list"
        options: [
            { label: "5", value: 5 },
            { label: "8", value: 8 },
            { label: "12", value: 12 },
            { label: "15", value: 15 }
        ]
        defaultValue: 8
    }
}
