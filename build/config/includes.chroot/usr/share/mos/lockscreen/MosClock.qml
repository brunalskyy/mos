/*
    mOS lock screen clock: Pixel-style stacked clock (Material You).
    Hours on top, minutes underneath in the accent colour, then the date.
    SPDX-FileCopyrightText: 2026 Bruno Woznicki
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root

    // Size of the big numbers, set by the lock screen
    property real digitSize: 160

    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    readonly property bool twelveHour: Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().indexOf("ap") !== -1
    property date now: new Date()

    readonly property string hours: {
        var h = now.getHours();
        if (twelveHour) {
            h = h % 12;
            if (h === 0) {
                h = 12;
            }
        }
        return (h < 10 ? "0" : "") + h;
    }
    readonly property string minutes: (now.getMinutes() < 10 ? "0" : "") + now.getMinutes()

    readonly property color hourColour: "#FFFFFF"
    readonly property color minuteColour: Qt.lighter(Kirigami.Theme.highlightColor, 1.45)

    spacing: -Math.round(digitSize * 0.2)

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Text {
        text: root.hours
        color: root.hourColour
        font.family: "Inter"
        font.weight: Font.DemiBold
        font.pixelSize: root.digitSize
        font.features: { "tnum": 1 }
        textFormat: Text.PlainText
        style: root.softwareRendering ? Text.Outline : Text.Normal
        styleColor: "#66000000"
    }

    Text {
        text: root.minutes
        color: root.minuteColour
        font.family: "Inter"
        font.weight: Font.DemiBold
        font.pixelSize: root.digitSize
        font.features: { "tnum": 1 }
        textFormat: Text.PlainText
        style: root.softwareRendering ? Text.Outline : Text.Normal
        styleColor: "#66000000"
    }

    Text {
        Layout.topMargin: Math.round(root.digitSize * 0.18)
        Layout.leftMargin: Math.round(root.digitSize * 0.04)
        text: Qt.formatDate(root.now, "dddd d MMMM")
        color: "#FFFFFF"
        opacity: 0.92
        font.family: "Inter"
        font.weight: Font.Medium
        font.pixelSize: Math.max(16, Math.round(root.digitSize * 0.16))
        textFormat: Text.PlainText
        style: root.softwareRendering ? Text.Outline : Text.Normal
        styleColor: "#66000000"
    }
}
