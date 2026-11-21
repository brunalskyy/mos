import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var d: backend.dateTime()
    property var zones: []
    property string filter: ""
    Connections { target: backend; function onJobDone(key) { if (key === "time") page.d = backend.dateTime() }
                  function onChanged() { page.d = backend.dateTime() } }
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: page.now = new Date() }

    Card {
        pad: 24
        Label { text: Qt.formatTime(page.now, page.d.h24 ? "HH:mm" : "h:mm AP"); color: Theme.textColour; font.pixelSize: 44; font.weight: Font.DemiBold }
        Label { text: Qt.formatDate(page.now, "dddd d MMMM yyyy"); color: Theme.textVariant; font.pixelSize: 16 }
    }
    Card {
        SettingRow {
            title: "Set time automatically"
            sub: "Use the internet to keep the clock right"
            MSwitch { checked: page.d.auto; onToggled: function (v) { backend.setAutoTime(v) } }
        }
        Divider {}
        SettingRow {
            title: "24-hour clock"
            sub: page.d.h24 ? "13:00" : "1:00 PM"
            MSwitch { checked: page.d.h24; onToggled: function (v) { backend.set24h(v) } }
        }
        Divider {}
        ListItem { title: "Time zone"; value: (page.d.timezone || "").replace(/_/g, " "); onClicked: { page.zones = backend.timezones(); tz.open() } }
    }

    Sheet {
        id: tz
        title: "Time zone"
        MField { Layout.fillWidth: true; placeholderText: "Search, e.g. London"; onTextChanged: page.filter = text.toLowerCase() }
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: 320
            clip: true
            model: page.zones.filter(function (z) { return page.filter === "" || z.toLowerCase().indexOf(page.filter.replace(/ /g, "_")) !== -1 }).slice(0, 200)
            delegate: ListItem {
                required property string modelData
                width: ListView.view.width
                title: modelData.replace(/_/g, " ")
                chevron: false
                selected: modelData === page.d.timezone
                onClicked: { backend.setTimezone(modelData); tz.close() }
            }
        }
    }
}
