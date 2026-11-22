// mOS setup wizard
// SPDX-FileCopyrightText: 2026 Bruno Woznicki
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ApplicationWindow {
    id: win
    width: 960
    height: 680
    minimumWidth: 820
    minimumHeight: 600
    visible: true
    // First run after installing: full screen, always on top, can't be closed until setup is done
    visibility: wizard.locked ? Window.FullScreen : Window.Windowed
    flags: wizard.locked ? (Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint) : Qt.Window
    onClosing: (close) => { if (wizard.locked && !wizard.finished) close.accepted = false }
    title: "Welcome to mOS"
    font.family: Theme.font
    color: Theme.surface

    readonly property var steps: ["welcome", "language", "wifi", "account", "look", "taskbar", "done"]
    property int step: 0
    function next() { if (step < steps.length - 1) step++ }
    function back() { if (step > 0) step-- }
    function toast(t) { toastLabel.text = t; toastBox.opacity = 1; toastTimer.restart() }
    Connections { target: backend; function onToast(t) { win.toast(t) } }

    // Soft Amber glow in the background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.surface }
            GradientStop { position: 1; color: Theme.mix(Theme.accent, Theme.surface, 0.82) }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 36
        spacing: 20

        // Progress dots
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8
            visible: win.step > 0
            Repeater {
                model: win.steps.length
                delegate: Rectangle {
                    required property int index
                    width: index === win.step ? 28 : 8; height: 8; radius: 4
                    color: index <= win.step ? Theme.primary : Theme.outline
                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
            }
        }

        // The current step
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Loader {
                id: stepLoader
                anchors.fill: parent
                source: "steps/" + win.steps[win.step] + ".qml"
                onLoaded: { slide.restart() }
                ParallelAnimation {
                    id: slide
                    NumberAnimation { target: stepLoader; property: "opacity"; from: 0; to: 1; duration: 260 }
                    NumberAnimation { target: stepLoader; property: "anchors.leftMargin"; from: 40; to: 0; duration: 320; easing.type: Easing.OutCubic }
                }
            }
        }

        // Buttons
        RowLayout {
            Layout.fillWidth: true
            visible: win.step > 0 && win.step < win.steps.length - 1
            PillButton { text: "Back"; outlined: true; onClicked: win.back() }
            Item { Layout.fillWidth: true }
            PillButton { text: "Skip"; outlined: true; visible: ["wifi", "account"].indexOf(win.steps[win.step]) >= 0; onClicked: win.next() }
            PillButton { text: "Next"; onClicked: win.next() }
        }
    }

    Rectangle {
        id: toastBox
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 96
        width: toastLabel.implicitWidth + 40; height: 48; radius: 24
        color: Theme.dark ? "#E6E0E9" : "#322F35"
        opacity: 0; visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Label { id: toastLabel; anchors.centerIn: parent; color: Theme.dark ? "#322F35" : "#F5EFF7"; font.pixelSize: 14 }
        Timer { id: toastTimer; interval: 3000; onTriggered: toastBox.opacity = 0 }
    }
}
