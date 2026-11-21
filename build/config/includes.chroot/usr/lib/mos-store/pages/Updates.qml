import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import components
import "../parts"

StorePage {
    id: up
    title: "Updates"
    property var apps: { store.jobs; store.updateCount; store.appCount; return store.installed() }
    readonly property var pending: apps.filter(function (a) { return a.newVersion !== "" })
    readonly property var rest: apps.filter(function (a) { return a.newVersion === "" })
    Component.onCompleted: store.refresh()

    Card {
        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            ToneIcon { name: "update"; tone: "#1E88E5"; size: 44 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label { text: up.pending.length ? up.pending.length + (up.pending.length === 1 ? " update" : " updates") + " ready"
                                                : "Your apps are up to date"
                        color: Theme.textColour; font.pixelSize: 17; font.weight: Font.DemiBold }
                Label { text: "mOS itself updates in Settings → General → Software update"; color: Theme.textVariant
                        font.pixelSize: 13; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }
            PillButton { visible: up.pending.length > 0; text: "Update all"; onClicked: store.updateAll() }
            PillButton { tonal: true; text: "mOS updates"; onClicked: store.openSoftwareUpdate() }
        }
        RowLayout {
            Layout.fillWidth: true
            Label { Layout.fillWidth: true; text: "Show download speed in"; color: Theme.textColour; font.pixelSize: 14 }
            Segmented {
                options: [{ value: "MB/s", label: "MB/s" }, { value: "Mbps", label: "Mbps" }]
                current: store.speedUnit
                onSelected: function (v) { store.setSpeedUnit(v) }
            }
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        visible: up.pending.length > 0
        spacing: 4
        Label { text: "Updates"; color: Theme.textColour; font.pixelSize: 22; font.weight: Font.Bold }
        Repeater {
            model: up.pending
            AppRow { required property var modelData; Layout.fillWidth: true; app: modelData
                     onOpen: function (id) { up.open(id) } }
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Label { text: "Your apps"; color: Theme.textColour; font.pixelSize: 22; font.weight: Font.Bold }
        Label { visible: up.rest.length === 0; text: "Apps you get from the mOS Store show up here."; color: Theme.textVariant; font.pixelSize: 14 }
        GridLayout {
            Layout.fillWidth: true
            columns: width > 900 ? 2 : 1
            columnSpacing: 16; rowSpacing: 4
            Repeater {
                model: up.rest
                AppRow { required property var modelData; Layout.fillWidth: true; app: modelData
                         onOpen: function (id) { up.open(id) } }
            }
        }
    }
}
