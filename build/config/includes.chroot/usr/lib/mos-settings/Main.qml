// mOS Settings — Material 3 settings app for mOS.
// SPDX-FileCopyrightText: 2026 Bruno Woznicki
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 1080
    height: 720
    minimumWidth: 820
    minimumHeight: 560
    visible: true
    title: "Settings"
    font.family: "Inter"

    // ---------- Material You colours from the accent ----------
    function mix(a, b, t) {
        // Qt.lighter(x, 1) turns a colour name like "#FFFFFF" into a real colour
        var ca = Qt.lighter(a, 1.0), cb = Qt.lighter(b, 1.0)
        return Qt.rgba(ca.r + (cb.r - ca.r) * t, ca.g + (cb.g - ca.g) * t, ca.b + (cb.b - ca.b) * t, 1)
    }
    readonly property bool dark: backend.dark
    readonly property color accent: backend.accent
    readonly property color primary: dark ? mix(accent, "#FFFFFF", 0.35) : mix(accent, "#000000", 0.12)
    readonly property color onPrimary: dark ? mix(accent, "#000000", 0.8) : "#FFFFFF"
    readonly property color primaryContainer: dark ? mix(accent, "#000000", 0.6) : mix(accent, "#FFFFFF", 0.78)
    readonly property color onPrimaryContainer: dark ? mix(accent, "#FFFFFF", 0.8) : mix(accent, "#000000", 0.7)
    readonly property color surface: dark ? mix(accent, "#141218", 0.94) : mix(accent, "#FFFBFF", 0.96)
    readonly property color surfaceContainer: dark ? mix(accent, "#1D1B20", 0.9) : mix(accent, "#F7F2FA", 0.9)
    readonly property color surfaceHigh: dark ? mix(accent, "#2B2930", 0.9) : "#FFFFFF"
    readonly property color onSurface: dark ? "#E6E0E9" : "#1D1B20"
    readonly property color onSurfaceVariant: dark ? "#CAC4D0" : "#49454F"
    readonly property color outline: dark ? "#49454F" : mix(accent, "#CAC4D0", 0.85)

    property string page: startPage
    property string query: ""

    color: surface

    // Sidebar items: id, title, subtitle, icon, colour, KDE module (empty = built in)
    readonly property var items: [
        { section: "Personalise" },
        { id: "style", title: "Wallpaper & style", sub: "Wallpaper, colours, dark mode", icon: "palette", tone: "#E8833A", module: "" },
        { id: "icons", title: "Icon shape", sub: "Circle, squircle or rounded", icon: "shapes", tone: "#D9488B", module: "" },
        { id: "lock", title: "Lock screen", sub: "Clock, timeout, password", icon: "lock", tone: "#7C5CFF", module: "kcm_screenlocker" },
        { section: "Connections" },
        { id: "wifi", title: "Wi-Fi & internet", sub: "Networks, VPN, hotspot", icon: "wifi", tone: "#2F7BEA", module: "kcm_networkmanagement" },
        { id: "bt", title: "Bluetooth", sub: "Headphones, mice, phones", icon: "bluetooth", tone: "#1E88E5", module: "kcm_bluetooth" },
        { section: "Device" },
        { id: "display", title: "Display", sub: "Resolution, scale, Night Light", icon: "display", tone: "#00897B", module: "kcm_kscreen" },
        { id: "sound", title: "Sound", sub: "Volume, speakers, microphone", icon: "sound", tone: "#E53935", module: "kcm_pulseaudio" },
        { id: "power", title: "Battery & power", sub: "Sleep, battery saver", icon: "battery", tone: "#43A047", module: "kcm_powerdevilprofilesconfig" },
        { id: "keyboard", title: "Keyboard", sub: "Layouts, shortcuts", icon: "keyboard", tone: "#6D4C41", module: "kcm_keyboard" },
        { id: "mouse", title: "Mouse & trackpad", sub: "Speed, scrolling, gestures", icon: "mouse", tone: "#546E7A", module: "kcm_touchpad" },
        { section: "System" },
        { id: "notifications", title: "Notifications", sub: "Do not disturb, pop-ups", icon: "bell", tone: "#F4511E", module: "kcm_notifications" },
        { id: "apps", title: "Default apps", sub: "Browser, email, files", icon: "apps", tone: "#8E24AA", module: "kcm_componentchooser" },
        { id: "time", title: "Date & time", sub: "Time zone, clock", icon: "clock", tone: "#3949AB", module: "kcm_clock" },
        { id: "language", title: "Language & region", sub: "Language, formats", icon: "globe", tone: "#00ACC1", module: "kcm_regionandlang" },
        { id: "users", title: "Users", sub: "Accounts on this computer", icon: "person", tone: "#5E35B1", module: "kcm_users" },
        { id: "about", title: "About mOS", sub: "Version, this computer", icon: "info", tone: "#757575", module: "" },
        { id: "more", title: "More settings", sub: "Every KDE setting", icon: "more", tone: "#616161", module: "systemsettings" }
    ]
    function itemFor(id) {
        for (var i = 0; i < items.length; i++)
            if (items[i].id === id) return items[i]
        return items[1]
    }
    function icon(name) { return Qt.resolvedUrl("icons/" + name + ".svg") }
    function ink(name) { return Qt.resolvedUrl("icons/" + name + (win.dark ? "-inkdark" : "-ink") + ".svg") }

    // ---------- small Material pieces ----------
    component ToneIcon: Rectangle {
        property string name
        property color tone
        property int size: 36
        width: size; height: size; radius: size / 2
        color: tone
        Image {
            anchors.centerIn: parent
            source: win.icon(parent.name)
            width: parent.size * 0.56; height: width
            sourceSize: Qt.size(width * 2, height * 2)
        }
    }

    component M3Switch: Item {
        id: sw
        property bool checked: false
        signal toggled(bool value)
        implicitWidth: 52; implicitHeight: 32
        Rectangle {
            anchors.fill: parent; radius: 16
            color: sw.checked ? win.primary : win.surfaceContainer
            border.width: sw.checked ? 0 : 2
            border.color: win.outline
            Behavior on color { ColorAnimation { duration: 150 } }
        }
        Rectangle {
            readonly property int d: sw.checked ? 24 : 16
            width: d; height: d; radius: d / 2
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? parent.width - d - 4 : 8
            color: sw.checked ? win.onPrimary : win.onSurfaceVariant
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 150 } }
            Behavior on height { NumberAnimation { duration: 150 } }
        }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: { sw.checked = !sw.checked; sw.toggled(sw.checked) }
        }
    }

    component Card: Rectangle {
        default property alias content: inner.data
        property int pad: 20
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + pad * 2
        radius: 24
        color: win.surfaceHigh
        border.width: win.dark ? 0 : 1
        border.color: Qt.rgba(0, 0, 0, 0.05)
        ColumnLayout {
            id: inner
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: parent.pad }
            spacing: 14
        }
    }

    component SettingRow: RowLayout {
        property string title
        property string sub
        spacing: 16
        Layout.fillWidth: true
        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            Label { text: title; color: win.onSurface; font.pixelSize: 16; font.weight: Font.Medium }
            Label { text: sub; color: win.onSurfaceVariant; font.pixelSize: 13; visible: sub !== ""; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }
    }

    component PillButton: Rectangle {
        property string text
        property bool tonal: false
        signal clicked()
        implicitWidth: lbl.implicitWidth + 48
        implicitHeight: 44
        radius: 22
        color: tonal ? win.primaryContainer : win.primary
        opacity: ma.pressed ? 0.85 : 1
        Label {
            id: lbl; anchors.centerIn: parent; text: parent.text
            color: parent.tonal ? win.onPrimaryContainer : win.onPrimary
            font.pixelSize: 15; font.weight: Font.DemiBold
        }
        MouseArea { id: ma; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked() }
    }

    // ---------- layout ----------
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar (inset, macOS-style, Material colours)
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 300
            Layout.margins: 10
            Layout.rightMargin: 0
            radius: 22
            color: win.surfaceContainer

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // Search
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: 24
                    color: win.surfaceHigh
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 10
                        Image {
                            source: win.ink("search"); sourceSize: Qt.size(40, 40)
                            Layout.preferredWidth: 20; Layout.preferredHeight: 20
                        }
                        TextField {
                            id: search
                            Layout.fillWidth: true
                            placeholderText: "Search settings"
                            placeholderTextColor: win.onSurfaceVariant
                            color: win.onSurface
                            font.pixelSize: 15
                            background: null
                            onTextChanged: win.query = text.toLowerCase()
                        }
                    }
                }

                // mOS Account card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 72
                    radius: 20
                    color: accMa.containsMouse ? Qt.darker(win.primaryContainer, 1.03) : win.primaryContainer
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 12
                        Rectangle {
                            width: 46; height: 46; radius: 23
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#FFD36B" }
                                GradientStop { position: 0.5; color: "#FF9A3C" }
                                GradientStop { position: 1; color: "#E8505B" }
                            }
                            Image { anchors.centerIn: parent; source: win.icon("account"); width: 26; height: 26; sourceSize: Qt.size(52, 52) }
                        }
                        ColumnLayout {
                            spacing: 1; Layout.fillWidth: true
                            Label { text: "mOS Account"; color: win.onPrimaryContainer; font.pixelSize: 16; font.weight: Font.DemiBold }
                            Label { text: "Sign in, sync and more"; color: win.onPrimaryContainer; opacity: 0.8; font.pixelSize: 13 }
                        }
                        Image { source: win.ink("chevron"); Layout.preferredWidth: 18; Layout.preferredHeight: 18; sourceSize: Qt.size(36, 36); opacity: 0.7 }
                    }
                    MouseArea { id: accMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: backend.launch("mos-account") }
                }

                // List
                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: win.items.filter(function (it) {
                        if (win.query === "") return true
                        if (it.section) return false
                        return (it.title + " " + it.sub).toLowerCase().indexOf(win.query) !== -1
                    })
                    delegate: Item {
                        required property var modelData
                        width: list.width
                        height: modelData.section ? 36 : 52
                        Label {
                            visible: !!modelData.section
                            text: modelData.section || ""
                            anchors.left: parent.left; anchors.leftMargin: 14
                            anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                            color: win.onSurfaceVariant
                            font.pixelSize: 12; font.weight: Font.DemiBold; font.letterSpacing: 0.4
                        }
                        Rectangle {
                            visible: !modelData.section
                            anchors.fill: parent
                            radius: 26
                            color: win.page === modelData.id ? win.primaryContainer
                                 : rowMa.containsMouse ? Qt.rgba(win.onSurface.r, win.onSurface.g, win.onSurface.b, 0.06) : "transparent"
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 14; spacing: 14
                                ToneIcon { name: modelData.icon || "info"; tone: modelData.tone || "#757575"; size: 34 }
                                Label {
                                    text: modelData.title || ""
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    color: win.page === modelData.id ? win.onPrimaryContainer : win.onSurface
                                    font.pixelSize: 15
                                    font.weight: win.page === modelData.id ? Font.DemiBold : Font.Normal
                                }
                            }
                            MouseArea {
                                id: rowMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: win.page = modelData.id
                            }
                        }
                    }
                }
            }
        }

        // Content
        ScrollView {
            id: scroller
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true

            ColumnLayout {
                width: Math.min(scroller.availableWidth - 64, 760)
                x: 32
                spacing: 18

                Item { implicitHeight: 18 }

                Label {
                    text: win.itemFor(win.page).title
                    color: win.onSurface
                    font.pixelSize: 34; font.weight: Font.DemiBold
                }

                Loader {
                    Layout.fillWidth: true
                    sourceComponent: win.page === "style" ? stylePage
                                   : win.page === "icons" ? iconsPage
                                   : win.page === "about" ? aboutPage
                                   : modulePage
                }

                Item { implicitHeight: 24 }
            }
        }
    }

    // ---------- pages ----------
    Component {
        id: stylePage
        ColumnLayout {
            spacing: 18
            Card {
                Label { text: "Wallpaper"; color: win.onSurface; font.pixelSize: 18; font.weight: Font.DemiBold }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 14; rowSpacing: 14
                    Repeater {
                        model: backend.wallpapers
                        delegate: ColumnLayout {
                            required property var modelData
                            spacing: 8
                            Layout.fillWidth: true
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: width * 10 / 16
                                radius: 18
                                color: win.surfaceContainer
                                clip: true
                                Image {
                                    anchors.fill: parent
                                    source: modelData.preview
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.width: 480
                                    layer.enabled: true
                                }
                                Rectangle { anchors.fill: parent; radius: 18; color: "transparent"; border.width: wpMa.containsMouse ? 3 : 0; border.color: win.primary }
                                MouseArea { id: wpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: backend.setWallpaper(modelData.image) }
                            }
                            Label { text: modelData.name; color: win.onSurfaceVariant; font.pixelSize: 13; Layout.alignment: Qt.AlignHCenter }
                        }
                    }
                }
            }
            Card {
                SettingRow {
                    title: "Colours from wallpaper"
                    sub: "Buttons, highlights and widgets match your wallpaper, like Material You"
                    M3Switch { checked: backend.accentFromWallpaper; onToggled: function (v) { backend.setAccentFromWallpaper(v) } }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: win.outline; opacity: 0.6 }
                SettingRow {
                    title: "Dark mode"
                    sub: "Dark backgrounds in mOS and your apps"
                    M3Switch { checked: backend.dark; onToggled: function (v) { backend.setDark(v) } }
                }
            }
            Card {
                SettingRow {
                    title: "Accent colour"
                    sub: backend.accentFromWallpaper ? "Picked from your wallpaper" : "Fixed colour"
                    Row {
                        spacing: 6
                        Repeater {
                            model: [win.primary, win.primaryContainer, win.accent, win.surfaceContainer]
                            delegate: Rectangle { required property color modelData; width: 28; height: 28; radius: 14; color: modelData; border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.08) }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: iconsPage
        ColumnLayout {
            spacing: 18
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: "Pick the shape for app icons. It changes every app on the taskbar, Start menu and desktop."
                color: win.onSurfaceVariant; font.pixelSize: 15
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 14
                Repeater {
                    model: [
                        { shape: "circle", name: "Circle", theme: "mOS" },
                        { shape: "squircle", name: "Squircle", theme: "mOS-Squircle" },
                        { shape: "rounded", name: "Rounded square", theme: "mOS-Rounded" }
                    ]
                    delegate: Rectangle {
                        id: shapeCard
                        required property var modelData
                        readonly property bool chosen: backend.iconShape === modelData.shape
                        Layout.fillWidth: true
                        implicitHeight: 220
                        radius: 24
                        color: chosen ? win.primaryContainer : win.surfaceHigh
                        border.width: chosen ? 2 : 1
                        border.color: chosen ? win.primary : Qt.rgba(0, 0, 0, 0.06)
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 14
                            Grid {
                                Layout.alignment: Qt.AlignHCenter
                                columns: 2; spacing: 10
                                Repeater {
                                    model: ["system-file-manager", "org.gnome.Epiphany", "org.gnome.Music", "utilities-terminal"]
                                    delegate: Image {
                                        required property string modelData
                                        width: 52; height: 52
                                        sourceSize: Qt.size(104, 104)
                                        source: "file:///usr/share/icons/" + shapeCard.modelData.theme + "/128x128/apps/" + modelData + ".png"
                                    }
                                }
                            }
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 6
                                Image { visible: chosen; source: win.ink("check"); Layout.preferredWidth: 18; Layout.preferredHeight: 18; sourceSize: Qt.size(36, 36) }
                                Label { text: modelData.name; color: chosen ? win.onPrimaryContainer : win.onSurface; font.pixelSize: 15; font.weight: Font.DemiBold }
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: backend.setIconShape(modelData.shape) }
                    }
                }
            }
        }
    }

    Component {
        id: aboutPage
        ColumnLayout {
            spacing: 18
            Card {
                pad: 28
                RowLayout {
                    spacing: 22
                    Image { source: "file:///usr/share/icons/hicolor/256x256/apps/mos-logo.png"; width: 96; height: 96; sourceSize: Qt.size(192, 192) }
                    ColumnLayout {
                        spacing: 4
                        Label { text: "mOS"; color: win.onSurface; font.pixelSize: 30; font.weight: Font.Bold }
                        Label { text: backend.about.version || "mOS"; color: win.onSurfaceVariant; font.pixelSize: 15 }
                        Label { text: "Made by Bruno Woznicki"; color: win.onSurfaceVariant; font.pixelSize: 13 }
                    }
                }
            }
            Card {
                Repeater {
                    model: [
                        { k: "Computer", v: backend.about.model },
                        { k: "Processor", v: backend.about.cpu },
                        { k: "Memory", v: backend.about.memory }
                    ]
                    delegate: RowLayout {
                        required property var modelData
                        visible: modelData.v !== ""
                        Layout.fillWidth: true
                        Label { text: modelData.k; color: win.onSurfaceVariant; font.pixelSize: 15; Layout.preferredWidth: 140 }
                        Label { text: modelData.v; color: win.onSurface; font.pixelSize: 15; font.weight: Font.Medium; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    }
                }
            }
            RowLayout {
                spacing: 12
                PillButton { text: "More about this computer"; tonal: true; onClicked: backend.openModule("kcm_about-distro") }
                PillButton { text: "mOS website"; tonal: true; onClicked: Qt.openUrlExternally("https://brunalskyy.github.io/mos/") }
            }
        }
    }

    Component {
        id: modulePage
        ColumnLayout {
            spacing: 18
            readonly property var it: win.itemFor(win.page)
            Card {
                pad: 28
                RowLayout {
                    spacing: 20
                    ToneIcon { name: it.icon; tone: it.tone; size: 64 }
                    ColumnLayout {
                        spacing: 4; Layout.fillWidth: true
                        Label { text: it.title; color: win.onSurface; font.pixelSize: 20; font.weight: Font.DemiBold }
                        Label { text: it.sub; color: win.onSurfaceVariant; font.pixelSize: 15; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    }
                }
                PillButton {
                    text: it.module === "systemsettings" ? "Open all settings" : "Open " + it.title.toLowerCase() + " settings"
                    onClicked: it.module === "systemsettings" ? backend.launch("systemsettings") : backend.openModule(it.module)
                }
            }
        }
    }
}
