import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var a: backend.accessibility()
    Connections { target: backend; function onChanged() { page.a = backend.accessibility() } }
    Card {
        SectionTitle { text: "Text size"; Layout.topMargin: 0 }
        Segmented {
            Layout.fillWidth: true
            options: [{ value: 9, label: "Small" }, { value: 10, label: "Normal" }, { value: 12, label: "Large" }, { value: 14, label: "Extra large" }]
            current: page.a.textSize
            onSelected: function (v) { backend.setTextSize(v) }
        }
        Label { text: "The quick brown fox jumps over the lazy dog"; color: Theme.onSurfaceVariant; font.pointSize: page.a.textSize; Layout.fillWidth: true; wrapMode: Text.WordWrap }
    }
    Card {
        SettingRow {
            title: "Reduce motion"
            sub: "Turn off animations like zooming windows"
            MSwitch { checked: page.a.reduceMotion; onToggled: function (v) { backend.setReduceMotion(v) } }
        }
        Divider {}
        SettingRow {
            title: "Colour filter"
            sub: "Makes colours easier to tell apart if you're colour blind"
            MSwitch { checked: page.a.colourFilter; onToggled: function (v) { backend.setColourFilter(v) } }
        }
    }
    Card {
        SectionTitle { text: "Zoom"; Layout.topMargin: 0 }
        Hint { text: "Zoom in on anything: press Win and + to zoom in, Win and − to zoom out." }
    }
}
