import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    Hint { text: "Meta is the Windows key (⌘ on a Mac keyboard)." }
    Card {
        pad: 18; gap: 0
        Repeater {
            model: backend.shortcuts
            delegate: ColumnLayout {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                spacing: 0
                Divider { visible: index > 0 }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 12; Layout.bottomMargin: 12
                    Label { Layout.fillWidth: true; text: modelData.what; color: Theme.textColour; font.pixelSize: 15 }
                    Row {
                        spacing: 6
                        Repeater {
                            model: modelData.keys.split(/\s+or\s+/)
                            Rectangle {
                                required property string modelData
                                width: k.implicitWidth + 20; height: 30; radius: 10
                                color: Theme.surfaceContainer
                                border.width: 1; border.color: Theme.outline
                                Label { id: k; anchors.centerIn: parent; text: modelData.replace(/\+/g, " + ")
                                        color: Theme.textColour; font.pixelSize: 13; font.weight: Font.DemiBold }
                            }
                        }
                    }
                }
            }
        }
    }
    RowLayout { PillButton { tonal: true; text: "Change shortcuts"; onClicked: backend.openShortcutEditor() } }
}
