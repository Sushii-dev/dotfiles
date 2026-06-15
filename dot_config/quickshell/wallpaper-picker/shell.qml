import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property var items: []
    readonly property color accent: "#89b4fa"
    readonly property color cardBg: "#1e1e2e"
    readonly property color surface: "#181825"

    function apply(path) {
        Quickshell.execDetached(["wallpaper-set", path]);
        Qt.quit();
    }

    FileView {
        id: manifest
        path: Quickshell.env("HOME") + "/.cache/wallpaper-picker/manifest.json"
        blockLoading: true
        onLoaded: {
            try {
                root.items = JSON.parse(text());
            } catch (e) {
                console.log("[wallpaper-picker] manifest parse failed:", e);
            }
        }
        onLoadFailed: console.log("[wallpaper-picker] no manifest")
    }

    PanelWindow {
        id: win
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "wallpaper-picker"
        exclusionMode: ExclusionMode.Ignore

        Item {
            id: scope
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: Qt.quit()

            // dimmed backdrop — click outside the card to dismiss
            Rectangle {
                anchors.fill: parent
                color: "#cc000000"
                MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.82, 1500)
                height: Math.min(parent.height * 0.82, 950)
                radius: 20
                color: root.surface
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                // swallow clicks so they don't hit the backdrop
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Wallpapers"
                            color: "white"
                            font.pixelSize: 24
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: root.items.length + " items   ·   Esc to close"
                            color: Qt.rgba(1, 1, 1, 0.45)
                            font.pixelSize: 13
                        }
                    }

                    Text {
                        visible: root.items.length === 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 15
                        text: "No wallpapers found.\nDrop images in ~/.local/share/wallpapers/ or videos in ~/.local/share/wallpapers-video/"
                    }

                    GridView {
                        id: grid
                        visible: root.items.length > 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        cellWidth: 312
                        cellHeight: 200
                        model: root.items
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Item {
                            width: grid.cellWidth
                            height: grid.cellHeight

                            Rectangle {
                                id: tile
                                anchors.fill: parent
                                anchors.margins: 8
                                radius: 14
                                color: root.cardBg
                                border.width: hover.hovered ? 2 : 1
                                border.color: hover.hovered ? root.accent : Qt.rgba(1, 1, 1, 0.08)
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: "file://" + modelData.thumb
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    sourceSize.width: 480
                                }

                                // gradient + label strip
                                Rectangle {
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                    height: 40
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 1.0; color: "#cc000000" }
                                    }
                                }
                                Text {
                                    anchors {
                                        left: parent.left; right: parent.right; bottom: parent.bottom
                                        leftMargin: 10; rightMargin: 10; bottomMargin: 8
                                    }
                                    text: modelData.name
                                    color: "white"
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                // video badge
                                Rectangle {
                                    visible: modelData.type === "video"
                                    anchors { top: parent.top; right: parent.right; margins: 8 }
                                    width: 26; height: 26; radius: 13
                                    color: "#cc000000"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "▶"
                                        color: "white"
                                        font.pixelSize: 11
                                    }
                                }

                                HoverHandler { id: hover }
                                TapHandler { onTapped: root.apply(modelData.path) }
                            }
                        }
                    }
                }
            }
        }
    }
}
