import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var b: backend.bluetooth()
    property bool scanning: false
    function reload() { b = backend.bluetooth() }
    Timer { interval: 4000; running: true; repeat: true; onTriggered: page.reload() }
    Connections {
        target: backend
        function onJobDone(key, ok, msg) { if (key === "bt-scan") page.scanning = false; if (key.indexOf("bt") === 0) page.reload() }
    }

    Card {
        SettingRow {
            title: "Bluetooth"
            sub: !page.b.available ? "There's no Bluetooth on this computer" : page.b.enabled ? "On — other devices can find this computer" : "Off"
            MSwitch { enabled: page.b.available; checked: page.b.enabled; onToggled: function (v) { backend.setBluetoothEnabled(v) } }
        }
    }

    RowLayout {
        visible: page.b.enabled
        SectionTitle { text: "Devices" }
        PillButton { text: page.scanning ? "Searching…" : "Add device"; busy: page.scanning; onClicked: { page.scanning = true; backend.bluetoothScan() } }
    }

    Card {
        visible: page.b.enabled
        pad: 10; gap: 2
        Repeater {
            model: page.b.devices || []
            delegate: ListItem {
                required property var modelData
                title: modelData.name
                sub: modelData.connected ? "Connected" : modelData.paired ? "Paired" : "Tap to pair"
                iconName: "bluetooth"
                tone: modelData.connected ? Theme.primary : "#90A4AE"
                selected: modelData.connected
                chevron: false
                PillButton {
                    visible: modelData.paired
                    text: modelData.connected ? "Disconnect" : "Connect"; tonal: true
                    onClicked: modelData.connected ? backend.bluetoothDisconnect(modelData.mac) : backend.bluetoothConnect(modelData.mac)
                }
                Rectangle {
                    visible: modelData.paired
                    width: 40; height: 40; radius: 20; color: rm.containsMouse ? Theme.alpha(Theme.onSurface, 0.08) : "transparent"
                    Image { anchors.centerIn: parent; source: Theme.ink("trash"); width: 20; height: 20; sourceSize: Qt.size(40, 40) }
                    MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: backend.bluetoothRemove(modelData.mac) }
                }
                onClicked: if (!modelData.paired) backend.bluetoothPair(modelData.mac)
            }
        }
        Hint { visible: (page.b.devices || []).length === 0; Layout.margins: 12
               text: "No devices yet. Put your headphones, mouse or phone in pairing mode, then tap Add device." }
    }
}
