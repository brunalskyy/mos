import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var p: backend.printers()
    Connections { target: backend; function onChanged() { page.p = backend.printers() } }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: page.p = backend.printers() }
    Hint { text: "Most Wi-Fi and USB printers show up here by themselves, no drivers needed." }
    Card {
        pad: 10; gap: 2
        visible: page.p.printers.length > 0
        Repeater {
            model: page.p.printers
            delegate: ListItem {
                required property var modelData
                title: modelData.name.replace(/_/g, " ")
                sub: modelData.state + (modelData.default ? " · Main printer" : "")
                iconName: "printer"; tone: "#546E7A"
                chevron: false
                PillButton { visible: !modelData.default; tonal: true; text: "Make main"; onClicked: backend.setDefaultPrinter(modelData.name) }
                PillButton { outlined: true; text: "Test page"; onClicked: backend.printTestPage(modelData.name) }
                PillButton { outlined: true; text: "Remove"; onClicked: backend.removePrinter(modelData.name) }
            }
        }
    }
    Card {
        visible: page.p.printers.length === 0
        pad: 28
        ToneIcon { Layout.alignment: Qt.AlignHCenter; name: "printer"; tone: "#546E7A"; size: 56 }
        Label { Layout.alignment: Qt.AlignHCenter; text: page.p.available ? "No printers yet" : "Printing isn't installed"
                color: Theme.textColour; font.pixelSize: 18; font.weight: Font.DemiBold }
        Hint { Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter
               text: "Turn your printer on and connect it to the same Wi-Fi, or plug it in with USB." }
    }
    RowLayout { PillButton { text: "Add a printer"; enabled: page.p.available; onClicked: backend.addPrinter() } }
}
