import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var p: backend.power()
    Timer { interval: 15000; running: true; repeat: true; onTriggered: page.p = backend.power() }
    Connections { target: backend; function onChanged() { page.p = backend.power() } }

    Card {
        visible: page.p.hasBattery
        RowLayout {
            spacing: 20
            Item {
                width: 96; height: 96
                Canvas {
                    id: ring
                    anchors.fill: parent
                    property real v: page.p.percent / 100
                    onVChanged: requestPaint()
                    onPaint: {
                        var c = getContext("2d"); c.reset()
                        c.lineWidth = 10; c.lineCap = "round"
                        c.strokeStyle = Theme.primaryContainer
                        c.beginPath(); c.arc(48, 48, 40, 0, 2 * Math.PI); c.stroke()
                        c.strokeStyle = page.p.percent <= 15 ? Theme.error : Theme.primary
                        c.beginPath(); c.arc(48, 48, 40, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * v); c.stroke()
                    }
                }
                Label { anchors.centerIn: parent; text: page.p.percent + "%"; color: Theme.onSurface; font.pixelSize: 22; font.weight: Font.DemiBold }
            }
            ColumnLayout {
                spacing: 4
                Label { text: page.p.state; color: Theme.onSurface; font.pixelSize: 20; font.weight: Font.DemiBold }
                Label { visible: page.p.timeLeft !== ""; text: page.p.timeLeft + (page.p.state === "Charging" ? " until full" : " left"); color: Theme.onSurfaceVariant }
                Label { visible: page.p.health !== ""; text: "Battery health " + page.p.health; color: Theme.onSurfaceVariant }
            }
        }
    }

    Card {
        visible: (page.p.profiles || []).length > 0
        SectionTitle { text: "Power mode"; Layout.topMargin: 0 }
        Segmented {
            Layout.fillWidth: true
            options: (page.p.profiles || []).map(function (x) {
                return { value: x, label: x === "power-saver" ? "Battery saver" : x === "balanced" ? "Balanced" : "Best performance" } })
            current: page.p.profile
            onSelected: function (v) { backend.setPowerProfile(v); page.p.profile = v }
        }
    }

    Card {
        SectionTitle { text: "When I'm away"; Layout.topMargin: 0 }
        Hint { text: "Turn off the screen after" }
        Segmented {
            Layout.fillWidth: true
            options: [{ value: 2, label: "2 min" }, { value: 5, label: "5 min" }, { value: 10, label: "10 min" }, { value: 30, label: "30 min" }, { value: 0, label: "Never" }]
            current: page.p.screenOff
            onSelected: function (v) { backend.setPowerTimeouts(v, page.p.sleep) }
        }
        Hint { text: "Go to sleep after" }
        Segmented {
            Layout.fillWidth: true
            options: [{ value: 5, label: "5 min" }, { value: 15, label: "15 min" }, { value: 30, label: "30 min" }, { value: 60, label: "1 hour" }, { value: 0, label: "Never" }]
            current: page.p.sleep
            onSelected: function (v) { backend.setPowerTimeouts(page.p.screenOff, v) }
        }
    }
}
