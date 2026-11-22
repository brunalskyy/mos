// mOS Apple Control Panel: fans, temperatures, keyboard and battery on your Mac
// SPDX-FileCopyrightText: 2026 Bruno Woznicki
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ApplicationWindow {
    id: win
    width: 920
    height: 720
    minimumWidth: 720
    minimumHeight: 560
    visible: true
    title: "Apple Control Panel"
    font.family: Theme.font
    color: Theme.surface

    property string fanMode: apple.saved.fan || "auto"
    property real manualRpm: apple.saved.rpm || (apple.fans.length ? apple.fans[0].min + 600 : 2000)

    function toast(t) { toastLabel.text = t; toastBox.opacity = 1; toastTimer.restart() }
    Connections { target: apple; function onToast(t) { win.toast(t) } }

    function tempColour(v) { return v < 60 ? Theme.good : v < 80 ? "#E8A33A" : Theme.error }

    ScrollView {
        id: scroller
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: Math.min(scroller.availableWidth - 64, 820)
            x: (scroller.availableWidth - width) / 2
            spacing: 18

            // ---------- header
            RowLayout {
                Layout.topMargin: 30
                spacing: 18
                Rectangle {
                    Layout.preferredWidth: 64; Layout.preferredHeight: 64; radius: 18
                    color: Theme.primaryContainer
                    Image { anchors.centerIn: parent; width: 40; height: 40; source: "image://icon/computer-laptop"; sourceSize: Qt.size(80, 80) }
                }
                ColumnLayout {
                    spacing: 2
                    Label { text: "Apple Control Panel"; color: Theme.textColour; font.pixelSize: 30; font.weight: Font.DemiBold }
                    Label { text: apple.isMac ? apple.niceModel : "This app is for Intel Macs"; color: Theme.textVariant; font.pixelSize: 15 }
                }
            }

            Card {
                visible: !apple.isMac || !apple.hasSmc
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap; color: Theme.textColour; font.pixelSize: 15
                    text: !apple.isMac ? "This computer isn't a Mac, so there's nothing to control here."
                                       : "mOS can't reach this Mac's fan chip (applesmc). Fans and temperatures need it."
                }
            }

            // ---------- fans
            Card {
                visible: apple.isMac && apple.fans.length > 0
                Layout.fillWidth: true
                SectionTitle { text: "Fans"; Layout.topMargin: 0 }
                Repeater {
                    model: apple.fans
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 16
                        ColumnLayout {
                            spacing: 0
                            Label { text: modelData.rpm + " RPM"; color: Theme.textColour; font.pixelSize: 28; font.weight: Font.DemiBold }
                            Label { text: modelData.name + " · " + modelData.min + "–" + modelData.max + " RPM"; color: Theme.textVariant; font.pixelSize: 13 }
                        }
                        Rectangle {
                            Layout.fillWidth: true; height: 10; radius: 5
                            color: Theme.secondaryContainer
                            Rectangle {
                                height: parent.height; radius: 5; color: Theme.primary
                                width: parent.width * Math.max(0.04, Math.min(1, modelData.rpm / Math.max(1, modelData.max)))
                                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }
                Segmented {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    enabled: !apple.busy
                    options: [{ label: "Automatic", value: "auto" }, { label: "Quiet", value: "quiet" },
                              { label: "Keep cool", value: "cool" }, { label: "Manual", value: "manual" }]
                    current: win.fanMode
                    onSelected: function (v) {
                        win.fanMode = v
                        if (v !== "manual") apple.setFan(v, 0)
                    }
                }
                Hint {
                    text: win.fanMode === "auto" ? "Your Mac decides, like on macOS."
                        : win.fanMode === "quiet" ? "Fans stay as slow as your Mac allows until it really needs cooling."
                        : win.fanMode === "cool" ? "Fans never drop below about half speed, so it stays cooler (and a bit louder)."
                        : "Pick a fixed speed. Your Mac's processor still slows itself down if it gets too hot."
                }
                RowLayout {
                    visible: win.fanMode === "manual" && apple.fans.length > 0
                    Layout.fillWidth: true
                    spacing: 14
                    MSlider {
                        Layout.fillWidth: true
                        from: apple.fans.length ? apple.fans[0].min : 1200
                        to: apple.fans.length ? apple.fans[0].max : 6500
                        step: 100
                        value: win.manualRpm
                        onMoved: function (v) { win.manualRpm = v }
                    }
                    Label { text: Math.round(win.manualRpm) + " RPM"; color: Theme.textColour; font.pixelSize: 15; Layout.preferredWidth: 90 }
                    PillButton { text: "Set"; enabled: !apple.busy; onClicked: apple.setFan("manual", Math.round(win.manualRpm)) }
                }
            }

            // ---------- temperatures
            Card {
                visible: apple.isMac && apple.temps.length > 0
                Layout.fillWidth: true
                SectionTitle { text: "Temperatures"; Layout.topMargin: 0 }
                GridLayout {
                    Layout.fillWidth: true
                    columns: width > 600 ? 4 : 3
                    columnSpacing: 12; rowSpacing: 12
                    Repeater {
                        model: apple.temps
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 84; radius: 18
                            color: Theme.surfaceContainer
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Label { Layout.alignment: Qt.AlignHCenter; text: Math.round(modelData.value) + "°C"
                                        color: win.tempColour(modelData.value); font.pixelSize: 24; font.weight: Font.DemiBold }
                                Label { Layout.alignment: Qt.AlignHCenter; text: modelData.name; color: Theme.textVariant; font.pixelSize: 13 }
                            }
                        }
                    }
                }
            }

            // ---------- keyboard
            Card {
                visible: apple.isMac
                Layout.fillWidth: true
                SectionTitle { text: "Keyboard"; Layout.topMargin: 0 }
                SettingRow {
                    visible: apple.keyboardLightMax > 0
                    title: "Keyboard light"
                    sub: apple.keyboardLight <= 0 ? "Off" : Math.round(100 * apple.keyboardLight / Math.max(1, apple.keyboardLightMax)) + "%"
                    MSlider {
                        Layout.preferredWidth: 240
                        from: 0; to: apple.keyboardLightMax; step: 1
                        value: Math.max(0, apple.keyboardLight)
                        onMoved: function (v) { apple.setKeyboardLight(Math.round(v)) }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Label { text: "Top row keys"; color: Theme.textColour; font.pixelSize: 15 }
                    Segmented {
                        Layout.fillWidth: true
                        enabled: !apple.busy
                        options: [{ label: "Brightness, volume and media", value: 1 }, { label: "F1 to F12", value: 2 }]
                        current: apple.fnMode === 2 ? 2 : 1
                        onSelected: function (v) { apple.setFnMode(v) }
                    }
                    Hint { text: "Hold fn to use the other one." }
                }
                SettingRow {
                    title: "Swap Cmd and Option"
                    sub: "Like a Windows keyboard: the key next to the space bar works as Alt"
                    MSwitch { checked: apple.swapped; enabled: !apple.busy; onToggled: function (v) { apple.setSwapped(v) } }
                }
            }

            // ---------- battery
            Card {
                visible: apple.isMac && apple.battery.present === true
                Layout.fillWidth: true
                SectionTitle { text: "Battery"; Layout.topMargin: 0 }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Repeater {
                        model: [
                            { big: (apple.battery.health || 0) + "%", small: "Health" },
                            { big: String(apple.battery.cycles || 0), small: "Charge cycles" },
                            { big: (apple.battery.percent || 0) + "%", small: apple.battery.status || "Charge" },
                            { big: apple.battery.condition || "", small: "Condition" }
                        ]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 84; radius: 18
                            color: Theme.surfaceContainer
                            ColumnLayout {
                                anchors.centerIn: parent
                                width: parent.width - 16
                                spacing: 2
                                Label { Layout.alignment: Qt.AlignHCenter; text: modelData.big; color: Theme.textColour
                                        font.pixelSize: modelData.big.length > 8 ? 15 : 24; font.weight: Font.DemiBold
                                        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                                Label { Layout.alignment: Qt.AlignHCenter; text: modelData.small; color: Theme.textVariant; font.pixelSize: 13 }
                            }
                        }
                    }
                }
                Hint { text: "MacBook batteries are usually fine down to 80% health. Below that, macOS would say \"Service recommended\"." }
            }

            Item { Layout.preferredHeight: 30 }
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
