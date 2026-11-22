// mOS Add widgets: like the widget gallery on iOS and macOS, with only mOS widgets
// SPDX-FileCopyrightText: 2026 Bruno Woznicki
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"
import "file:///usr/share/plasma/plasmoids/org.mos.clock/contents/ui" as ClockUi
import "file:///usr/share/plasma/plasmoids/org.mos.battery/contents/ui" as BatteryUi
import "file:///usr/share/plasma/plasmoids/org.mos.calendar/contents/ui" as CalendarUi
import "file:///usr/share/plasma/plasmoids/org.mos.weather/contents/ui" as WeatherUi
import "file:///usr/share/plasma/plasmoids/org.mos.notes/contents/ui" as NotesUi

ApplicationWindow {
    id: win
    width: 1000
    height: 640
    minimumWidth: 880
    minimumHeight: 560
    visible: true
    title: "Add widgets"
    font.family: Theme.font
    color: Theme.surface

    // Sizes are in desktop grid units: small 8×8, medium 17×8, large 17×17 (like iOS)
    readonly property var widgets: [
        { id: "org.mos.clock", name: "Clock", desc: "A flower-shaped clock with hands. Big or small.",
          sizes: [{ label: "Small", w: 8, h: 8 }, { label: "Large", w: 12, h: 12 }] },
        { id: "org.mos.calendar", name: "Calendar", desc: "Today's date when it's small, the whole month when it's large.",
          sizes: [{ label: "Small", w: 8, h: 8 }, { label: "Large", w: 17, h: 17 }] },
        { id: "org.mos.weather", name: "Weather", desc: "The weather where you are. Medium adds the next five hours.",
          sizes: [{ label: "Small", w: 8, h: 8 }, { label: "Medium", w: 17, h: 8 }] },
        { id: "org.mos.battery", name: "Battery", desc: "A ring that fills with your battery level, with a bolt when charging.",
          sizes: [{ label: "Small", w: 8, h: 8 }] },
        { id: "org.mos.notes", name: "Notes", desc: "A sticky note. Click it and type, it saves by itself.",
          sizes: [{ label: "Small", w: 8, h: 8 }, { label: "Medium", w: 17, h: 8 }, { label: "Large", w: 17, h: 17 }] },
        { id: "org.mos.glance", name: "At a glance", desc: "The date and the weather in big white letters, like a Pixel.",
          sizes: [{ label: "Wide", w: 20, h: 5 }] }
    ]
    property int current: 0
    property int size: 0
    readonly property var item: widgets[current]
    readonly property real px: 12   // preview pixels per grid unit
    onCurrentChanged: size = 0

    function toast(t) { toastLabel.text = t; toastBox.opacity = 1; toastTimer.restart() }
    Connections { target: gallery; function onToast(t) { win.toast(t) } }

    // The real widget faces, so the previews look exactly like the desktop
    Component { id: clockC; ClockUi.ClockFace { accent: Theme.accent; dark: Theme.dark } }
    Component { id: batteryC; BatteryUi.BatteryFace { accent: Theme.accent; dark: Theme.dark; percent: 82 } }
    Component { id: calendarC; CalendarUi.CalendarFace { accent: Theme.accent; dark: Theme.dark } }
    Component {
        id: weatherC
        WeatherUi.WeatherFace {
            accent: Theme.accent; dark: Theme.dark; place: "Your town"; temp: 18; code: 2; high: 21; low: 12
            hours: [{ hour: "14", temp: 18, code: 2, day: true }, { hour: "15", temp: 19, code: 1, day: true },
                    { hour: "16", temp: 19, code: 0, day: true }, { hour: "17", temp: 17, code: 3, day: true },
                    { hour: "18", temp: 15, code: 61, day: true }]
        }
    }
    Component { id: notesC; NotesUi.NotesFace { accent: Theme.accent; dark: Theme.dark; text: "Shopping:\n• Milk\n• Oranges"; enabled: false } }
    Component {
        id: glanceC
        Item {
            Column {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text { text: Qt.formatDate(new Date(), "dddd d MMMM"); color: "white"; font.family: "Inter"; font.pixelSize: parent.parent.height * 0.32 }
                Text { text: "18°C · Partly cloudy"; color: "white"; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: parent.parent.height * 0.2 }
            }
        }
    }
    function face(id) {
        return { "org.mos.clock": clockC, "org.mos.battery": batteryC, "org.mos.calendar": calendarC,
                 "org.mos.weather": weatherC, "org.mos.notes": notesC, "org.mos.glance": glanceC }[id]
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------- the widgets
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 250
            color: Theme.surfaceContainer
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 4
                Label { text: "Widgets"; color: Theme.textColour; font.pixelSize: 26; font.weight: Font.DemiBold; Layout.leftMargin: 8; Layout.bottomMargin: 10 }
                Repeater {
                    model: win.widgets
                    Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        height: 52; radius: 26
                        color: win.current === index ? Theme.primaryContainer : ma.containsMouse ? Theme.alpha(Theme.textColour, 0.06) : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 14; spacing: 12
                            Item {
                                Layout.preferredWidth: 36; Layout.preferredHeight: 36
                                Loader {
                                    anchors.centerIn: parent
                                    width: modelData.id === "org.mos.glance" ? 36 : 34
                                    height: modelData.id === "org.mos.glance" ? 14 : 34
                                    sourceComponent: modelData.id === "org.mos.glance" ? null : win.face(modelData.id)
                                }
                                Rectangle {
                                    visible: modelData.id === "org.mos.glance"
                                    anchors.centerIn: parent; width: 34; height: 34; radius: 9
                                    color: Theme.mix(Theme.accent, "#000000", 0.35)
                                    Text { anchors.centerIn: parent; text: new Date().getDate(); color: "white"; font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: 15 }
                                }
                            }
                            Label {
                                text: modelData.name; Layout.fillWidth: true
                                color: win.current === index ? Theme.primaryContainerText : Theme.textColour
                                font.pixelSize: 15; font.weight: win.current === index ? Font.DemiBold : Font.Normal
                            }
                        }
                        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.current = index }
                    }
                }
                Item { Layout.fillHeight: true }
                Label {
                    Layout.fillWidth: true; Layout.leftMargin: 8
                    wrapMode: Text.WordWrap; color: Theme.textVariant; font.pixelSize: 12
                    text: "To move, resize or remove widgets, right-click the desktop and pick Edit widgets."
                }
            }
        }

        // ---------- the chosen widget
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 28
            spacing: 6
            Label { text: win.item.name; color: Theme.textColour; font.pixelSize: 30; font.weight: Font.DemiBold }
            Label { text: win.item.desc; color: Theme.textVariant; font.pixelSize: 15; wrapMode: Text.WordWrap; Layout.fillWidth: true }

            // Previews on your wallpaper; click a size to pick it, double-click to add it straight away
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 14
                radius: 24
                clip: true
                color: Theme.mix(Theme.accent, "#000000", 0.55)
                Image {
                    anchors.fill: parent
                    source: backend.wallpaper ? (String(backend.wallpaper).indexOf("file:") === 0 ? backend.wallpaper : "file://" + backend.wallpaper)
                                            : "file:///usr/share/wallpapers/mOS/contents/images/2880x1800.png"
                    fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 1200
                    opacity: 0.9
                }
                Rectangle { anchors.fill: parent; color: "black"; opacity: 0.18 }
                Row {
                    anchors.centerIn: parent
                    spacing: 30
                    Repeater {
                        model: win.item.sizes
                        Column {
                            required property var modelData
                            required property int index
                            spacing: 12
                            Item {
                                width: modelData.w * win.px; height: modelData.h * win.px
                                scale: pick.pressed ? 0.95 : (win.size === index ? 1.04 : 1)
                                Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.002 } }
                                Loader { anchors.fill: parent; sourceComponent: win.face(win.item.id) }
                                Rectangle {
                                    anchors.fill: parent; anchors.margins: -6
                                    radius: 30; color: "transparent"
                                    border.width: 3; border.color: "white"
                                    opacity: win.size === index && win.item.sizes.length > 1 ? 0.9 : 0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }
                                MouseArea {
                                    id: pick; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: win.size = index
                                    onDoubleClicked: gallery.add(win.item.id, modelData.w, modelData.h, win.item.name)
                                }
                            }
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label; color: "white"; font.pixelSize: 14; font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12
                Label {
                    Layout.fillWidth: true
                    color: Theme.textVariant; font.pixelSize: 13
                    text: win.item.sizes.length > 1 ? "Pick a size, then add it." : ""
                }
                PillButton {
                    text: "Add " + win.item.sizes[Math.min(win.size, win.item.sizes.length - 1)].label.toLowerCase() + " widget"
                    onClicked: {
                        var s = win.item.sizes[Math.min(win.size, win.item.sizes.length - 1)]
                        gallery.add(win.item.id, s.w, s.h, win.item.name)
                    }
                }
            }
        }
    }

    // Toast
    Rectangle {
        id: toastBox
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 26
        width: toastLabel.implicitWidth + 40; height: 48; radius: 24
        color: Theme.dark ? "#E6E0E9" : "#322F35"
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Label { id: toastLabel; anchors.centerIn: parent; color: Theme.dark ? "#322F35" : "#F4EFF4"; font.pixelSize: 14 }
        Timer { id: toastTimer; interval: 2600; onTriggered: toastBox.opacity = 0 }
    }
}
