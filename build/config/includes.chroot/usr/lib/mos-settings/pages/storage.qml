import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var s: backend.storage
    property bool scanning: true
    Component.onCompleted: backend.scanStorage()
    Connections { target: backend; function onJobDone(key) { if (key === "storage") { page.scanning = false; page.s = backend.storage } } }
    function gb(b) { return (b / 1e9).toFixed(b > 1e10 ? 0 : 1) + " GB" }
    readonly property var colours: ["#2F7BEA", "#00ACC1", "#E8833A", "#D9488B", "#8E5CF6", "#43A047", "#F4511E", "#90A4AE"]

    Card {
        pad: 24
        Label {
            text: page.s.total ? page.gb(page.s.free) + " free" : "Checking…"
            color: Theme.textColour; font.pixelSize: 26; font.weight: Font.DemiBold
        }
        Label { visible: !!page.s.total; text: page.gb(page.s.used) + " used of " + page.gb(page.s.total); color: Theme.textVariant }
        // Stacked bar
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 22; radius: 11; color: Theme.surfaceContainer; clip: true
            Row {
                anchors.fill: parent
                Repeater {
                    model: page.s.parts || []
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: parent.width * modelData.bytes / Math.max(1, page.s.total)
                        height: parent.height
                        color: page.colours[index % page.colours.length]
                    }
                }
            }
        }
        Repeater {
            model: page.s.parts || []
            delegate: RowLayout {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Rectangle { width: 12; height: 12; radius: 6; color: page.colours[index % page.colours.length] }
                Label { text: modelData.label; color: Theme.textColour; Layout.fillWidth: true }
                Label { text: page.gb(modelData.bytes); color: Theme.textVariant }
            }
        }
        Hint { visible: page.scanning; text: "Adding it all up…" }
    }
    RowLayout {
        PillButton { text: "Manage apps"; tonal: true; onClicked: Nav.go("apps") }
        PillButton { text: "Open Files"; tonal: true; onClicked: backend.openApp("org.kde.dolphin") }
    }
}
