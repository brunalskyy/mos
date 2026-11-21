import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    readonly property var u: backend.updateApi.info
    readonly property var o: backend.updateApi.options
    readonly property bool working: u.state === "checking" || u.state === "downloading" || u.state === "installing"
    Component.onCompleted: if (u.state === "idle") backend.updateApi.check()

    Card {
        pad: 26
        RowLayout {
            spacing: 18
            Rectangle {
                width: 64; height: 64; radius: 32
                color: page.u.state === "available" || page.u.state === "restart" ? Theme.primary : Theme.primaryContainer
                Image {
                    anchors.centerIn: parent; width: 34; height: 34; sourceSize: Qt.size(68, 68)
                    source: page.u.state === "uptodate" || page.u.state === "done" ? Theme.ink("check") : (page.u.state === "available" || page.u.state === "restart" ? Theme.icon("update") : Theme.ink("update"))
                    RotationAnimation on rotation { running: page.u.state === "checking"; from: 0; to: 360; duration: 1200; loops: Animation.Infinite }
                }
            }
            ColumnLayout {
                spacing: 3
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    text: page.u.state === "available" && page.u.mos && page.u.mos.name ? page.u.mos.name + " is ready" : (page.u.message || "Software update")
                    color: Theme.textColour; font.pixelSize: 22; font.weight: Font.DemiBold
                }
                Label {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap
                    color: Theme.textVariant
                    text: page.u.state === "available" ? page.u.count + " update" + (page.u.count === 1 ? "" : "s") + (page.u.downloadSizeText ? " · " + page.u.downloadSizeText : "")
                        : page.working ? (page.u.phase || "")
                        : "mOS " + page.u.current + " · last checked " + page.u.lastChecked
                }
            }
        }

        // Progress: bar, percent, speed and time left
        ColumnLayout {
            visible: page.u.state === "downloading" || page.u.state === "installing"
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 10; radius: 5; color: Theme.primaryContainer
                Rectangle { width: parent.width * Math.max(0.02, page.u.progress / 100); height: parent.height; radius: 5; color: Theme.primary
                            Behavior on width { NumberAnimation { duration: 300 } } }
            }
            RowLayout {
                Label { text: page.u.progress + "%"; color: Theme.textColour; font.weight: Font.DemiBold }
                Label { text: page.u.speed ? "· " + page.u.speed : ""; color: Theme.textVariant }
                Item { Layout.fillWidth: true }
                Label { text: page.u.eta || ""; color: Theme.textVariant }
            }
        }

        RowLayout {
            spacing: 12
            PillButton { visible: page.u.state === "available"; text: "Update now"; onClicked: backend.updateApi.install() }
            PillButton { visible: page.u.state === "restart"; text: "Restart now"; onClicked: backend.updateApi.restart() }
            PillButton { visible: !page.working && page.u.state !== "restart"; text: "Check for updates"; tonal: true; onClicked: backend.updateApi.check() }
        }
    }

    // What's in it
    Card {
        visible: page.u.state === "available"
        SectionTitle { text: "What's new"; Layout.topMargin: 0; visible: !!(page.u.mos && page.u.mos.name) }
        Repeater {
            model: page.u.mos && page.u.mos.notes ? page.u.mos.notes : []
            delegate: Label { required property string modelData; text: "•  " + modelData; color: Theme.textColour; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }
        ListItem { visible: (page.u.system || []).length > 0; title: "System updates"; sub: (page.u.system || []).length + " packages, incl. security fixes"; iconName: "shield"; tone: "#3949AB"; chevron: false }
        ListItem { visible: (page.u.apps || []).length > 0; title: "App updates"; sub: (page.u.apps || []).map(function (a) { return a.name }).slice(0, 4).join(", "); iconName: "apps"; tone: "#F4511E"; chevron: false }
        Hint { visible: page.u.restart; text: "Some updates need a restart to finish." }
    }

    Card {
        SettingRow {
            title: "Download updates automatically"
            sub: "Get updates ready in the background, then install when you choose"
            MSwitch { checked: page.o.autoDownload; onToggled: function (v) { backend.updateApi.setOption("autoDownload", v) } }
        }
        Divider {}
        SettingRow {
            title: "mOS Insider"
            sub: backend.accountApi.signedIn ? "Get new mOS features early (they might have bugs)" : "Sign in to your mOS Account to join"
            MSwitch { enabled: backend.accountApi.signedIn; checked: page.o.insider; onToggled: function (v) { backend.updateApi.setOption("insider", v) } }
        }
        Divider {}
        SettingRow {
            title: "Show download speed in"
            Segmented {
                options: [{ value: "MB/s", label: "MB/s" }, { value: "Mbps", label: "Mbps" }]
                current: page.o.unit
                onSelected: function (v) { backend.updateApi.setOption("unit", v) }
            }
        }
    }

    Card {
        visible: (page.o.history || []).length > 0
        SectionTitle { text: "Update history"; Layout.topMargin: 0 }
        Repeater {
            model: (page.o.history || []).slice(0, 6)
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Label { text: modelData.what; color: Theme.textColour; Layout.fillWidth: true; elide: Text.ElideRight }
                Label { text: modelData.when; color: Theme.textVariant }
            }
        }
    }
}
