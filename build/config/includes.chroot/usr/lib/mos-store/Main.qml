// mOS Store — apps for mOS, from Flathub.
// SPDX-FileCopyrightText: 2026 Bruno Woznicki
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Effects
import components
import "parts"

ApplicationWindow {
    id: win
    width: 1180
    height: 800
    minimumWidth: 820
    minimumHeight: 600
    visible: true
    title: "mOS Store"
    font.family: Theme.font
    color: Theme.surface

    property string tab: "today"
    property var stack: []          // app pages opened on top of the tab
    property string query: ""
    readonly property string openId: stack.length ? stack[stack.length - 1] : ""

    function openApp(id) { if (id && id !== openId) { var s = stack.slice(); s.push(id); stack = s } }
    function back() { var s = stack.slice(); s.pop(); stack = s }
    function goTab(t) { stack = []; tab = t }

    Component.onCompleted: if (startApp) openApp(startApp)
    Connections { target: store; function onToast(t) { win.toast(t) }; function onOpenApp(id) { win.openApp(id) } }

    // ---- the tab page
    Loader {
        id: page
        anchors.fill: parent
        visible: win.openId === ""
        source: win.tab === "today" ? "pages/Today.qml" : win.tab === "apps" ? "pages/Browse.qml"
              : win.tab === "games" ? "pages/Games.qml" : win.tab === "updates" ? "pages/Updates.qml" : "pages/Search.qml"
        onLoaded: { item.opacity = 0; fade.restart() }
        NumberAnimation { id: fade; target: page.item; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
        Connections { target: page.item; ignoreUnknownSignals: true; function onOpen(id) { win.openApp(id) } }
    }

    // ---- an app's page (slides in from the right)
    Loader {
        id: appPage
        anchors.fill: parent
        active: win.openId !== ""
        source: "pages/AppPage.qml"
        onLoaded: { item.appId = Qt.binding(function () { return win.openId }); slide.restart() }
        NumberAnimation { id: slide; target: appPage; property: "x"; from: 60; to: 0; duration: 260; easing.type: Easing.OutCubic }
        Connections { target: appPage.item; ignoreUnknownSignals: true
                      function onOpen(id) { win.openApp(id) }
                      function onBack() { win.back() } }
    }

    // ---- loading
    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        visible: store.loading || store.appCount === 0
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16
            BusyIndicator { Layout.alignment: Qt.AlignHCenter; running: store.loading }
            Label { Layout.alignment: Qt.AlignHCenter; text: store.status; color: Theme.textVariant; font.pixelSize: 15
                    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; Layout.maximumWidth: 420 }
        }
    }

    // ---- iOS 27 style capsule tab bar (floating, glassy) with search on its own circle
    RowLayout {
        id: bar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12
        z: 10

        Item {
            id: capsule
            Layout.preferredWidth: tabsRow.implicitWidth + 12
            Layout.preferredHeight: 64
            Rectangle {
                id: glass
                anchors.fill: parent
                radius: height / 2
                color: Theme.alpha(Theme.surfaceHigh, 0.86)
                border.width: 1
                border.color: Theme.alpha(Theme.dark ? "#FFFFFF" : "#000000", Theme.dark ? 0.10 : 0.06)
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.8; shadowOpacity: 0.22; shadowVerticalOffset: 4 }
            }
            // the bubble that slides to the chosen tab
            Rectangle {
                id: bubble
                readonly property Item target: tabRep.count ? tabRep.itemAt(Math.max(0, win.tabs.indexOf(win.tab))) : null
                visible: win.tab !== "search" && target !== null
                x: target ? tabsRow.x + target.x : 0
                y: 6
                width: target ? target.width : 0
                height: parent.height - 12
                radius: height / 2
                color: Theme.alpha(Theme.primary, Theme.dark ? 0.28 : 0.16)
                Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                Behavior on width { NumberAnimation { duration: 220 } }
            }
            Row {
                id: tabsRow
                anchors.centerIn: parent
                Repeater {
                    id: tabRep
                    model: [{ id: "today", label: "Today", icon: "today" }, { id: "apps", label: "Apps", icon: "apps" },
                            { id: "games", label: "Games", icon: "game" }, { id: "updates", label: "Updates", icon: "download" }]
                    Item {
                        required property var modelData
                        readonly property bool on: win.tab === modelData.id && win.openId === ""
                        width: 92; height: 52
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Image {
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: Theme.ink(modelData.icon); sourceSize: Qt.size(48, 48); width: 22; height: 22
                                layer.enabled: parent.parent.on
                                layer.effect: MultiEffect { colorization: 1; colorizationColor: Theme.primary }
                            }
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: parent.parent.on ? Theme.primary : Theme.textVariant
                                font.pixelSize: 11; font.weight: Font.DemiBold
                            }
                        }
                        // badge with the number of updates
                        Rectangle {
                            visible: modelData.id === "updates" && store.updateCount > 0
                            x: parent.width / 2 + 6; y: 4
                            width: Math.max(18, badge.implicitWidth + 8); height: 18; radius: 9
                            color: Theme.error
                            Label { id: badge; anchors.centerIn: parent; text: store.updateCount; color: Theme.surface
                                    font.pixelSize: 10; font.weight: Font.Bold }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.goTab(modelData.id) }
                    }
                }
            }
        }
        // Search on its own glass circle
        Rectangle {
            Layout.preferredWidth: 64; Layout.preferredHeight: 64
            radius: 32
            color: win.tab === "search" ? Theme.primary : Theme.alpha(Theme.surfaceHigh, 0.86)
            border.width: 1
            border.color: Theme.alpha(Theme.dark ? "#FFFFFF" : "#000000", Theme.dark ? 0.10 : 0.06)
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.8; shadowOpacity: 0.22; shadowVerticalOffset: 4 }
            Image {
                anchors.centerIn: parent
                source: win.tab === "search" ? Theme.icon("search") : Theme.ink("search")
                sourceSize: Qt.size(48, 48); width: 24; height: 24
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.goTab("search") }
        }
    }
    readonly property var tabs: ["today", "apps", "games", "updates"]

    // ---- short messages
    function toast(text) { toastLabel.text = text; toastBox.opacity = 1; toastTimer.restart() }
    Rectangle {
        id: toastBox
        z: 20
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bar.top
        anchors.bottomMargin: 14
        width: toastLabel.implicitWidth + 40; height: 44; radius: 22
        color: Theme.dark ? "#E6E0E9" : "#322F35"
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Label { id: toastLabel; anchors.centerIn: parent; color: Theme.dark ? "#322F35" : "#F4EFF4"; font.pixelSize: 14 }
        Timer { id: toastTimer; interval: 3200; onTriggered: toastBox.opacity = 0 }
    }
}
