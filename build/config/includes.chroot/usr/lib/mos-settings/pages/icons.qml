import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    spacing: 18
    Card {
        SettingRow {
            title: "Themed icons"
            sub: "Like a Pixel: every icon in one colour that matches your wallpaper, light or dark"
            MSwitch { checked: backend.themedIcons; onToggled: function (v) { backend.setThemedIcons(v) } }
        }
    }
    Hint { text: "Pick the shape for app icons. Every app follows it — on the taskbar, in the Start menu and on the desktop — even apps you install later." }
    RowLayout {
        Layout.fillWidth: true
        spacing: 14
        Repeater {
            model: [
                { shape: "circle", name: "Circle", theme: "mOS" },
                { shape: "squircle", name: "Squircle", theme: "mOS-Squircle" },
                { shape: "rounded", name: "Rounded square", theme: "mOS-Rounded" }
            ]
            delegate: Rectangle {
                id: card
                required property var modelData
                readonly property bool chosen: backend.iconShape === modelData.shape
                Layout.fillWidth: true
                implicitHeight: 230
                radius: 26
                color: chosen ? Theme.primaryContainer : Theme.surfaceHigh
                border.width: chosen ? 2 : 1
                border.color: chosen ? Theme.primary : Qt.rgba(0, 0, 0, 0.06)
                scale: m.pressed ? 0.97 : 1
                Behavior on scale { NumberAnimation { duration: 100 } }
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 14
                    Grid {
                        Layout.alignment: Qt.AlignHCenter
                        columns: 2; spacing: 10
                        Repeater {
                            model: ["system-file-manager", "org.gnome.Epiphany", "org.gnome.Music", "utilities-terminal"]
                            delegate: Image {
                                required property string modelData
                                width: 56; height: 56
                                sourceSize: Qt.size(112, 112)
                                source: "file:///usr/share/icons/" + card.modelData.theme + "/128x128/apps/" + modelData + ".png"
                            }
                        }
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6
                        Image { visible: card.chosen; source: Theme.ink("check"); Layout.preferredWidth: 18; Layout.preferredHeight: 18; sourceSize: Qt.size(36, 36) }
                        Label { text: card.modelData.name; color: card.chosen ? Theme.primaryContainerText : Theme.textColour; font.pixelSize: 15; font.weight: Font.DemiBold }
                    }
                }
                MouseArea { id: m; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: backend.setIconShape(card.modelData.shape) }
            }
        }
    }
}
