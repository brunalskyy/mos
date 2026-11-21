import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var s: backend.sound()
    property bool dragging: false
    Timer { interval: 3000; running: !page.dragging; repeat: true; onTriggered: page.s = backend.sound() }
    Connections { target: backend; function onChanged() { page.s = backend.sound() } }

    Card {
        SectionTitle { text: "Volume"; Layout.topMargin: 0 }
        RowLayout {
            Rectangle {
                width: 40; height: 40; radius: 20; color: page.s.muted ? Theme.primaryContainer : "transparent"
                Image { anchors.centerIn: parent; source: Theme.ink("sound"); width: 22; height: 22; sourceSize: Qt.size(44, 44); opacity: page.s.muted ? 0.4 : 1 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { backend.setMuted(!page.s.muted); page.s.muted = !page.s.muted } }
            }
            MSlider { Layout.fillWidth: true; from: 0; to: 100; value: page.s.volume
                      onMoved: function (v) { page.dragging = true; backend.setVolume(v) }
                      onReleased: page.dragging = false }
            Label { text: (page.s.volume || 0) + "%"; color: Theme.onSurfaceVariant; Layout.preferredWidth: 44 }
        }
        Divider {}
        Hint { text: "Play sound through" }
        Repeater {
            model: page.s.outputs || []
            delegate: ListItem {
                required property var modelData
                title: modelData.label; iconName: "sound"; tone: modelData.default ? Theme.primary : "#90A4AE"
                selected: modelData.default; chevron: false
                onClicked: backend.setOutput(modelData.name)
            }
        }
    }
    Card {
        visible: (page.s.inputs || []).length > 0
        SectionTitle { text: "Microphone"; Layout.topMargin: 0 }
        RowLayout {
            Rectangle {
                width: 40; height: 40; radius: 20; color: page.s.micMuted ? Theme.primaryContainer : "transparent"
                Image { anchors.centerIn: parent; source: Theme.ink("mic"); width: 22; height: 22; sourceSize: Qt.size(44, 44); opacity: page.s.micMuted ? 0.4 : 1 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { backend.setMicMuted(!page.s.micMuted); page.s.micMuted = !page.s.micMuted } }
            }
            MSlider { Layout.fillWidth: true; from: 0; to: 100; value: page.s.micVolume
                      onMoved: function (v) { page.dragging = true; backend.setMicVolume(v) }
                      onReleased: page.dragging = false }
            Label { text: (page.s.micVolume || 0) + "%"; color: Theme.onSurfaceVariant; Layout.preferredWidth: 44 }
        }
        Repeater {
            model: page.s.inputs || []
            delegate: ListItem {
                required property var modelData
                title: modelData.label; iconName: "mic"; tone: modelData.default ? Theme.primary : "#90A4AE"
                selected: modelData.default; chevron: false
                onClicked: backend.setInput(modelData.name)
            }
        }
    }
    Card { visible: !page.s.available; Hint { text: "Couldn't find any sound devices." } }
}
