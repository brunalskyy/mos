// mOS lock screen clock, Windows 11 style: big time with the date under it,
// centred near the top. It fades and slides away when the sign-in box appears.
// SPDX-FileCopyrightText: 2026 Bruno Woznicki
// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick

Item {
    id: clock
    property int digitSize: 140
    property bool hidden: false          // true while the sign-in box is showing
    property date now: new Date()
    implicitWidth: Math.max(timeText.implicitWidth, dateText.implicitWidth)
    implicitHeight: timeText.implicitHeight + dateText.implicitHeight
    width: implicitWidth
    height: implicitHeight
    opacity: hidden ? 0 : 1
    transform: Translate { y: clock.hidden ? -40 : 0; Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } } }
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

    Timer { interval: 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: clock.now = new Date() }

    Text {
        id: timeText
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatTime(clock.now, Qt.locale().timeFormat(Locale.ShortFormat).replace(":ss", ""))
        color: "white"
        font.family: "Inter"
        font.pixelSize: clock.digitSize
        font.weight: Font.DemiBold
        font.letterSpacing: -clock.digitSize * 0.02
        style: Text.Raised
        styleColor: Qt.rgba(0, 0, 0, 0.25)
    }
    Text {
        id: dateText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: timeText.bottom
        anchors.topMargin: -clock.digitSize * 0.08
        text: Qt.formatDate(clock.now, "dddd d MMMM")
        color: "white"
        font.family: "Inter"
        font.pixelSize: Math.round(clock.digitSize * 0.2)
        font.weight: Font.Medium
        style: Text.Raised
        styleColor: Qt.rgba(0, 0, 0, 0.3)
    }
}
