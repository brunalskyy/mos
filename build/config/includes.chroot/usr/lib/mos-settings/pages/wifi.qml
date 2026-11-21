import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var w: backend.wifi()
    property string busySsid: ""
    function reload() { w = backend.wifi() }
    Timer { interval: 6000; running: true; repeat: true; onTriggered: page.reload() }
    Connections {
        target: backend
        function onJobDone(key, ok, msg) {
            if (key.indexOf("wifi") === 0) { page.busySsid = ""; page.reload() }
            if (key === "wifi-connect" && !ok && msg === "Wrong password") pw.open()
        }
    }

    Card {
        SettingRow {
            title: "Wi-Fi"
            sub: !page.w.available ? "Wi-Fi isn't available on this computer"
               : page.w.connected !== "" ? "Connected to " + page.w.connected
               : page.w.enabled ? "Not connected" : "Off"
            MSwitch { enabled: page.w.available; checked: page.w.enabled; onToggled: function (v) { backend.setWifiEnabled(v) } }
        }
        ListItem {
            visible: page.w.wired !== ""
            title: "Ethernet"; sub: "Connected to " + page.w.wired; iconName: "wired"; tone: "#00897B"; chevron: false
        }
    }

    RowLayout {
        visible: page.w.enabled
        SectionTitle { text: "Networks" }
        PillButton { text: "Refresh"; tonal: true; onClicked: { backend.wifiRescan() } }
    }

    Card {
        visible: page.w.enabled
        gap: 2
        pad: 10
        Repeater {
            model: page.w.networks || []
            delegate: ListItem {
                required property var modelData
                title: modelData.ssid
                sub: modelData.active ? "Connected" : page.busySsid === modelData.ssid ? "Connecting…" : modelData.saved ? "Saved" : (modelData.secure ? "Secured" : "Open")
                iconName: "wifi"
                tone: modelData.active ? Theme.primary : (modelData.signal > 60 ? "#2F7BEA" : modelData.signal > 35 ? "#5C8FE0" : "#9AA7BF")
                value: modelData.signal + "%"
                selected: modelData.active
                chevron: false
                Image { visible: modelData.secure; source: Theme.ink("lock-small"); width: 18; height: 18; sourceSize: Qt.size(36, 36) }
                onClicked: {
                    if (modelData.active) { netSheet.net = modelData; netSheet.open() }
                    else if (modelData.secure && !modelData.saved) { pw.ssid = modelData.ssid; pw.open() }
                    else { page.busySsid = modelData.ssid; backend.wifiConnect(modelData.ssid, "") }
                }
            }
        }
        Hint { visible: (page.w.networks || []).length === 0; text: "Looking for networks…"; Layout.margins: 12 }
    }

    Sheet {
        id: pw
        property string ssid: ""
        title: "Connect to " + ssid
        MField { id: pass; Layout.fillWidth: true; placeholderText: "Password"; echoMode: show.checked ? TextInput.Normal : TextInput.Password; onAccepted: go.clicked() }
        RowLayout {
            MSwitch { id: show }
            Label { text: "Show password"; color: Theme.onSurface } }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            PillButton { text: "Cancel"; outlined: true; onClicked: pw.close() }
            PillButton { id: go; text: "Connect"; onClicked: { page.busySsid = pw.ssid; backend.wifiConnect(pw.ssid, pass.text); pass.text = ""; pw.close() } }
        }
    }

    Sheet {
        id: netSheet
        property var net: ({})
        title: net.ssid || ""
        Hint { text: "Connected · signal " + (netSheet.net.signal || 0) + "%" }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            PillButton { text: "Forget"; outlined: true; onClicked: { backend.wifiForget(netSheet.net.ssid); netSheet.close() } }
            PillButton { text: "Disconnect"; tonal: true; onClicked: { backend.wifiDisconnect(netSheet.net.ssid); netSheet.close() } }
        }
    }
}
