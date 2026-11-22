// mOS password pop-up
// SPDX-FileCopyrightText: 2026 Bruno Woznicki
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic
import QtQuick.Layouts
import components

ApplicationWindow {
    id: win
    width: 440
    height: body.implicitHeight + 52
    minimumWidth: 440; maximumWidth: 440
    visible: false
    title: "mOS · Password needed"
    flags: Qt.Dialog | Qt.WindowStaysOnTopHint
    color: Theme.surface
    font.family: Theme.font

    readonly property var d: agent.d
    property bool showDetails: false

    Connections {
        target: agent
        function onShowDialog() {
            field.text = ""
            win.showDetails = false
            win.x = (Screen.width - win.width) / 2
            win.y = (Screen.height - win.height) / 2 - 40
            win.show(); win.raise(); win.requestActivate()
            pop.restart()
            field.forceActiveFocus()
        }
        function onHideDialog() { win.hide() }
        function onWrongPassword() { field.text = ""; shake.restart(); field.forceActiveFocus() }
    }
    onClosing: function (close) { close.accepted = false; agent.cancel() }

    Item {
        id: card
        anchors.fill: parent
        transform: Translate { id: shift }

        ColumnLayout {
            id: body
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 28 }
            spacing: 14

            // lock in a tonal circle
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 64; height: 64; radius: 32
                color: Theme.primaryContainer
                scale: 1
                NumberAnimation on scale { id: pop; from: 0.6; to: 1; duration: 320; easing.type: Easing.OutBack }
                Image { anchors.centerIn: parent; width: 30; height: 30; sourceSize: Qt.size(60, 60)
                        source: Theme.dark ? Theme.icon("lock") : Theme.ink("lock") }
            }
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: win.d.title || "Password needed"
                color: Theme.textColour
                font.pixelSize: 22; font.weight: Font.Bold
            }
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: win.d.message || ""
                wrapMode: Text.WordWrap
                color: Theme.textVariant
                font.pixelSize: 14; lineHeight: 1.2
            }

            // who is approving
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: 60
                radius: 20
                color: Theme.surfaceContainer
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12; anchors.rightMargin: 12
                    spacing: 12
                    Item {
                        width: 38; height: 38
                        RoundImage { anchors.fill: parent; source: win.d.avatar || ""; visible: (win.d.avatar || "") !== "" }
                        Rectangle {
                            anchors.fill: parent; radius: 19; color: Theme.primary
                            visible: (win.d.avatar || "") === ""
                            Label { anchors.centerIn: parent; text: (win.d.fullName || "?").charAt(0).toUpperCase()
                                    color: Theme.primaryText; font.pixelSize: 16; font.weight: Font.Bold }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label { Layout.fillWidth: true; text: win.d.fullName || ""; elide: Text.ElideRight
                                color: Theme.textColour; font.pixelSize: 15; font.weight: Font.DemiBold }
                        Label { Layout.fillWidth: true; text: win.d.user || ""; elide: Text.ElideRight
                                color: Theme.textVariant; font.pixelSize: 12 }
                    }
                    Label {
                        visible: (win.d.users || []).length > 1
                        text: "Switch"
                        color: Theme.primary; font.pixelSize: 13; font.weight: Font.DemiBold
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: userMenu.popup() }
                    }
                }
                Menu {
                    id: userMenu
                    Repeater {
                        model: win.d.users || []
                        MenuItem { required property int index; required property string modelData
                                   text: modelData; onTriggered: agent.chooseUser(index) }
                    }
                }
            }

            MField {
                id: field
                Layout.fillWidth: true
                echoMode: TextInput.Password
                placeholderText: win.d.prompt || "Password"
                enabled: !win.d.busy
                onAccepted: if (text.length) agent.submit(text)
            }
            Label {
                Layout.fillWidth: true
                visible: (win.d.error || "") !== ""
                text: win.d.error || ""
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                color: Theme.error
                font.pixelSize: 13
            }

            // details for the curious
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: win.showDetails ? "Hide details" : "Details"
                color: Theme.primary
                font.pixelSize: 12; font.weight: Font.DemiBold
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.showDetails = !win.showDetails }
            }
            Label {
                Layout.fillWidth: true
                visible: win.showDetails
                text: (win.d.detail || "") + "\n" + (win.d.action || "")
                wrapMode: Text.WrapAnywhere
                color: Theme.textVariant
                font.pixelSize: 11
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 10
                PillButton { Layout.fillWidth: true; outlined: true; text: "Cancel"; onClicked: agent.cancel() }
                PillButton {
                    Layout.fillWidth: true
                    text: win.d.busy ? "Checking…" : "Allow"
                    enabled: !win.d.busy && field.text.length > 0
                    onClicked: agent.submit(field.text)
                }
            }
        }
    }

    // shake when the password is wrong
    SequentialAnimation {
        id: shake
        NumberAnimation { target: shift; property: "x"; to: -12; duration: 50 }
        NumberAnimation { target: shift; property: "x"; to: 12; duration: 70 }
        NumberAnimation { target: shift; property: "x"; to: -8; duration: 60 }
        NumberAnimation { target: shift; property: "x"; to: 6; duration: 50 }
        NumberAnimation { target: shift; property: "x"; to: 0; duration: 40 }
    }
    Shortcut { sequence: "Escape"; onActivated: agent.cancel() }
}
