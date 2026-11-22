// mOS sign-in picture, Windows 7 style: your picture in a glossy glass frame
// with your name under it.
// SPDX-FileCopyrightText: 2026 Bruno Woznicki
// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick

Item {
    id: tile
    property string name
    property string image                 // file:// URL, or "" for the mOS logo
    property int size: 168
    width: size + 80
    height: frame.height + nameText.implicitHeight + 18

    Rectangle {
        id: frame
        anchors.horizontalCenter: parent.horizontalCenter
        width: tile.size; height: tile.size
        radius: Math.round(tile.size * 0.045)   // slightly rounded, like Windows 7
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.8)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.62) }
            GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.2) }
            GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.1) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.34) }
        }
        // soft shadow under the frame
        Rectangle {
            z: -1
            anchors.fill: parent
            anchors.topMargin: 8; anchors.bottomMargin: -10; anchors.leftMargin: 4; anchors.rightMargin: 4
            radius: parent.radius
            color: Qt.rgba(0, 0, 0, 0.28)
        }
        // the picture (square with rounded corners, clipped by a rounded rectangle)
        Rectangle {
            id: photoBox
            anchors.fill: parent
            anchors.margins: 3                       // the picture fills the frame, just inside the glass rim
            radius: 2
            color: "transparent"
            clip: true
            Image {
                anchors.fill: parent
                source: tile.image !== "" ? tile.image : "file:///usr/share/mos/avatar-default.png"
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(320, 320)
                smooth: true; mipmap: true
            }
        }
        // the Windows 7 glass shine over the top half
        Rectangle {
            anchors.left: photoBox.left; anchors.right: photoBox.right; anchors.top: photoBox.top
            height: photoBox.height * 0.46
            radius: photoBox.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.38) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.04) }
            }
        }
    }
    Text {
        id: nameText
        anchors.top: frame.bottom
        anchors.topMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        text: tile.name
        color: "white"
        font.family: "Inter"
        font.pixelSize: Math.round(tile.size * 0.17)
        font.weight: Font.Medium
        style: Text.Raised
        styleColor: Qt.rgba(0, 0, 0, 0.45)
    }
}
