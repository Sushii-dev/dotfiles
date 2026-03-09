import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "chezmoiStatus"

    ColumnLayout {
        width: parent.width
        spacing: Theme.spacingM

        StyledText {
            text: "Check Interval (seconds)"
            font.pixelSize: Theme.fontSizeNormal
            color: Theme.surfaceText
        }

        DankTextInput {
            Layout.fillWidth: true
            text: root.getSettingValue("checkInterval", "300")
            placeholderText: "300"
            inputMethodHints: Qt.ImhDigitsOnly
            onTextChanged: {
                const val = parseInt(text);
                if (val && val >= 30) {
                    root.setSettingValue("checkInterval", val);
                }
            }
        }

        StyledText {
            text: "Minimum 30 seconds. Default is 300 (5 minutes)."
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.outline
        }
    }
}
