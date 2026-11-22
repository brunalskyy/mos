// mOS Settings — Material 3 settings app for mOS.
// SPDX-FileCopyrightText: 2026 Bruno Woznicki
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "components"

ApplicationWindow {
    // Set from Python when Settings is opened again on a page (only one window)
    property string openPage: ""
    onOpenPageChanged: if (openPage !== "") { if (isGeneral(openPage)) { Nav.top("general"); Nav.go(openPage) } else Nav.top(openPage); openPage = "" }
    id: win
    width: 1100
    height: 740
    minimumWidth: 860
    minimumHeight: 580
    visible: true
    title: "Settings"
    font.family: Theme.font
    color: Theme.surface

    // Sidebar: id, title, icon, colour. Pages live in pages/<id>.qml
    readonly property var sections: [
        { section: "Connections" },
        { id: "wifi", title: "Wi-Fi & internet", icon: "wifi", tone: "#2F7BEA", keys: "network wireless ethernet internet" },
        { id: "bluetooth", title: "Bluetooth", icon: "bluetooth", tone: "#1E88E5", keys: "headphones devices pair" },
        { section: "Personalise" },
        { id: "style", title: "Wallpaper & style", icon: "palette", tone: "#E8833A", keys: "background colour dark mode auto accent theme material glass effects animations wobbly" },
        { id: "icons", title: "Icon shape", icon: "shapes", tone: "#D9488B", keys: "circle squircle rounded" },
        { id: "taskbar", title: "Taskbar", icon: "taskbar", tone: "#5C6BC0", keys: "dock panel floating pinned" },
        { id: "lock", title: "Lock screen", icon: "lockscreen", tone: "#7C5CFF", keys: "password clock timeout" },
        { section: "Device" },
        { id: "display", title: "Display", icon: "display", tone: "#00897B", keys: "screen brightness resolution scale night shift light" },
        { id: "sound", title: "Sound", icon: "sound", tone: "#E53935", keys: "volume speakers microphone audio" },
        { id: "power", title: "Battery & power", icon: "battery", tone: "#43A047", keys: "sleep power mode energy" },
        { section: "System" },
        { id: "notifications", title: "Notifications", icon: "bell", tone: "#F4511E", keys: "do not disturb alerts" },
        { id: "privacy", title: "Privacy & security", icon: "shield", tone: "#3949AB", keys: "camera microphone permissions" },
        { id: "general", title: "General", icon: "general", tone: "#616161", keys: "about update storage apps language date time users accessibility reset startup login fonts shortcuts keys printers printing" }
    ]
    // Pages that live inside General (they get a back button)
    readonly property var generalPages: [
        { id: "about", title: "About", icon: "info", tone: "#757575", sub: "mOS version, this computer" },
        { id: "update", title: "Software update", icon: "update", tone: "#1E88E5", sub: "mOS, system and app updates" },
        { id: "storage", title: "Storage", icon: "storage", tone: "#8E24AA", sub: "What's using space" },
        { id: "apps", title: "Apps", icon: "apps", tone: "#F4511E", sub: "Installed apps, default apps" },
        { id: "language", title: "Language & region", icon: "globe", tone: "#00ACC1", sub: "Language, formats" },
        { id: "datetime", title: "Date & time", icon: "clock", tone: "#3949AB", sub: "Time zone, 24-hour clock" },
        { id: "keyboard", title: "Keyboard", icon: "keyboard", tone: "#6D4C41", sub: "Layouts" },
        { id: "mouse", title: "Mouse & trackpad", icon: "mouse", tone: "#546E7A", sub: "Speed, scrolling, tap to click" },
        { id: "fonts", title: "Fonts", icon: "font", tone: "#8D6E63", sub: "Font and text size in apps" },
        { id: "shortcuts", title: "Keyboard shortcuts", icon: "shortcut", tone: "#5C6BC0", sub: "Spotlight, screenshots, windows" },
        { id: "printers", title: "Printers", icon: "printer", tone: "#546E7A", sub: "Add and manage printers" },
        { id: "startup", title: "Startup apps", icon: "update", tone: "#43A047", sub: "Apps that open when you log in" },
        { id: "users", title: "Users", icon: "person", tone: "#5E35B1", sub: "People who use this computer" },
        { id: "accessibility", title: "Accessibility", icon: "access", tone: "#00897B", sub: "Text size, motion, colour filters" },
        { id: "reset", title: "Reset", icon: "reset", tone: "#E53935", sub: "Put mOS back to how it started" }
    ]
    readonly property var extraPages: [
        { id: "account", title: "mOS Account" }
    ]
    function titleFor(id) {
        var all = sections.concat(generalPages).concat(extraPages)
        for (var i = 0; i < all.length; i++) if (all[i].id === id) return all[i].title
        return ""
    }
    function isGeneral(id) {
        for (var i = 0; i < generalPages.length; i++) if (generalPages[i].id === id) return true
        return false
    }
    property string query: ""
    // Opened straight on a page inside General (e.g. from an update notification): back goes to General
    Component.onCompleted: if (isGeneral(Nav.page)) Nav.trail = ["general"]

    // Short message at the bottom ("Connected to Home Wi-Fi")
    function toast(text) { toastLabel.text = text; toastBox.opacity = 1; toastTimer.restart() }
    Connections { target: backend; function onToast(t) { win.toast(t) } }
    Connections {
        target: backend
        function onJobDone(key, ok, msg) {
            if (msg && msg !== "ok" && msg.length < 120 && msg.indexOf("\n") < 0) win.toast(msg)
            else if (!ok) win.toast("That didn't work")
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------- sidebar (inset, Material colours)
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 300
            Layout.margins: 10
            Layout.rightMargin: 0
            radius: 24
            color: Theme.surfaceContainer

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: 24
                    color: Theme.surfaceHigh
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 10
                        Image { source: Theme.ink("search"); sourceSize: Qt.size(40, 40); Layout.preferredWidth: 20; Layout.preferredHeight: 20 }
                        TextField {
                            Layout.fillWidth: true
                            placeholderText: "Search settings"
                            placeholderTextColor: Theme.textVariant
                            color: Theme.textColour
                            font.pixelSize: 15
                            background: null
                            onTextChanged: win.query = text.toLowerCase()
                        }
                    }
                }

                // mOS Account
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 72
                    radius: 22
                    color: accMa.containsMouse || Nav.page === "account" ? Qt.darker(Theme.primaryContainer, 1.04) : Theme.primaryContainer
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 12
                        Rectangle {
                            width: 46; height: 46; radius: 23
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#FFD36B" }
                                GradientStop { position: 0.5; color: "#FF9A3C" }
                                GradientStop { position: 1; color: "#E8505B" }
                            }
                            Image {
                                anchors.centerIn: parent
                                visible: backend.accountApi.photo === ""
                                source: Theme.icon("account"); width: 26; height: 26; sourceSize: Qt.size(52, 52)
                            }
                            RoundImage { anchors.fill: parent; visible: backend.accountApi.photo !== ""; source: backend.accountApi.photo }
                        }
                        ColumnLayout {
                            spacing: 1; Layout.fillWidth: true
                            Label {
                                text: backend.accountApi.signedIn ? backend.accountApi.name : "mOS Account"
                                color: Theme.primaryContainerText; font.pixelSize: 16; font.weight: Font.DemiBold
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            Label {
                                text: backend.accountApi.signedIn ? "mOS Account" : "Sign in, sync and more"
                                color: Theme.primaryContainerText; opacity: 0.8; font.pixelSize: 13
                            }
                        }
                        Image { source: Theme.ink("chevron"); Layout.preferredWidth: 18; Layout.preferredHeight: 18; sourceSize: Qt.size(36, 36); opacity: 0.7 }
                    }
                    MouseArea { id: accMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Nav.top("account") }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds

                    // Liquid pill: one pill that stretches like a droplet to the page you pick
                    // (the front edge races ahead, the back edge catches up)
                    property Item pillOwner: null
                    Rectangle {
                        id: pill
                        parent: list.contentItem
                        z: -1
                        x: 0
                        width: list.width
                        radius: 25
                        color: Theme.primaryContainer
                        visible: list.pillOwner !== null && list.pillOwner.current
                        property real targetTop: list.pillOwner ? list.pillOwner.y : 0
                        property real targetBottom: list.pillOwner ? list.pillOwner.y + list.pillOwner.height : 0
                        property real top: targetTop
                        property real bottom: targetBottom
                        property bool down: true
                        property bool ready: false
                        onTargetTopChanged: down = targetTop >= top
                        y: top
                        height: Math.max(20, bottom - top)
                        Behavior on top { enabled: pill.ready; SpringAnimation { spring: pill.down ? 2.2 : 4.2; damping: 0.3; epsilon: 0.25 } }
                        Behavior on bottom { enabled: pill.ready; SpringAnimation { spring: pill.down ? 4.2 : 2.2; damping: 0.3; epsilon: 0.25 } }
                        Component.onCompleted: Qt.callLater(function () { pill.ready = true })
                    }

                    model: {
                        if (win.query === "") return win.sections
                        var hits = []
                        var all = win.sections.concat(win.generalPages)
                        for (var i = 0; i < all.length; i++) {
                            var it = all[i]
                            if (it.section) continue
                            if ((it.title + " " + (it.keys || "") + " " + (it.sub || "")).toLowerCase().indexOf(win.query) !== -1) hits.push(it)
                        }
                        return hits
                    }
                    delegate: Item {
                        id: row
                        required property var modelData
                        width: list.width
                        height: modelData.section ? 34 : 50
                        readonly property bool current: Nav.page === modelData.id || (modelData.id === "general" && win.isGeneral(Nav.page))
                        onCurrentChanged: if (current) list.pillOwner = row
                        Component.onCompleted: if (current) list.pillOwner = row
                        Label {
                            visible: !!row.modelData.section
                            text: row.modelData.section || ""
                            anchors.left: parent.left; anchors.leftMargin: 14
                            anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                            color: Theme.textVariant
                            font.pixelSize: 12; font.weight: Font.DemiBold; font.letterSpacing: 0.4
                        }
                        Rectangle {
                            visible: !row.modelData.section
                            anchors.fill: parent
                            radius: 25
                            color: !row.current && rowMa.containsMouse ? Theme.alpha(Theme.textColour, 0.06) : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 9; anchors.rightMargin: 14; spacing: 14
                                ToneIcon { name: row.modelData.icon || "info"; tone: row.modelData.tone || "#757575"; size: 32 }
                                Label {
                                    text: row.modelData.title || ""
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    color: row.current ? Theme.primaryContainerText : Theme.textColour
                                    font.pixelSize: 15
                                    font.weight: row.current ? Font.DemiBold : Font.Normal
                                }
                            }
                            MouseArea {
                                id: rowMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (win.isGeneral(row.modelData.id)) { Nav.top("general"); Nav.go(row.modelData.id) }
                                    else Nav.top(row.modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---------- page
        ScrollView {
            id: scroller
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true

            ColumnLayout {
                id: pageColumn
                width: Math.min(scroller.availableWidth - 64, 780)
                x: Math.max(32, (scroller.availableWidth - width) / 2)
                spacing: 18

                Item { implicitHeight: 14 }

                RowLayout {
                    spacing: 6
                    Rectangle {
                        visible: Nav.canGoBack
                        width: 44; height: 44; radius: 22
                        color: backMa.containsMouse ? Theme.alpha(Theme.textColour, 0.07) : "transparent"
                        Image { anchors.centerIn: parent; source: Theme.ink("back"); width: 22; height: 22; sourceSize: Qt.size(44, 44) }
                        MouseArea { id: backMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Nav.back() }
                    }
                    Label {
                        text: win.titleFor(Nav.page)
                        color: Theme.textColour
                        font.pixelSize: 34; font.weight: Font.DemiBold
                    }
                }

                Loader {
                    id: pageLoader
                    Layout.fillWidth: true
                    source: "pages/" + Nav.page + ".qml"
                    onLoaded: fade.restart()
                    NumberAnimation { id: fade; target: pageLoader; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
                }

                Item { implicitHeight: 32 }
            }
        }
    }

    // ---------- toast
    Rectangle {
        id: toastBox
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        width: toastLabel.implicitWidth + 40
        height: 48
        radius: 24
        color: Theme.dark ? "#E6E0E9" : "#322F35"
        opacity: 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Label { id: toastLabel; anchors.centerIn: parent; color: Theme.dark ? "#322F35" : "#F5EFF7"; font.pixelSize: 14 }
        Timer { id: toastTimer; interval: 3200; onTriggered: toastBox.opacity = 0 }
    }
}
