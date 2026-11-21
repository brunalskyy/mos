import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import QtQuick.Effects
import components

// Big Today card: a screenshot with the app on top ("APP OF THE DAY")
Item {
    id: hero
    property var app: ({})
    property string label
    signal open(string id)
    implicitHeight: 380
    scale: ma.pressed ? 0.985 : 1
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Item {
        id: content
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle { anchors.fill: parent; color: Theme.primaryContainer }
        Image {
            anchors.fill: parent
            source: hero.app.shot || ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            verticalAlignment: Image.AlignTop
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.35; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.78) }
            }
        }
    }
    Item {
        id: mask; anchors.fill: parent; visible: false; layer.enabled: true
        Rectangle { anchors.fill: parent; radius: 32; color: "black" }
    }
    MultiEffect { anchors.fill: parent; source: content; maskEnabled: true; maskSource: mask
                  shadowEnabled: true; shadowBlur: 0.7; shadowOpacity: 0.25; shadowVerticalOffset: 6 }

    Label {
        anchors { left: parent.left; top: parent.top; margins: 26 }
        text: hero.label
        color: "white"
        font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1.2
        style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.3)
    }
    RowLayout {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 24 }
        spacing: 16
        AppIcon { source: hero.app.icon || ""; size: 64 }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Label { Layout.fillWidth: true; text: hero.app.name || ""; color: "white"; elide: Text.ElideRight
                    font.pixelSize: 24; font.weight: Font.Bold }
            Label { Layout.fillWidth: true; text: hero.app.summary || ""; color: Qt.rgba(1, 1, 1, 0.85); elide: Text.ElideRight
                    font.pixelSize: 14 }
        }
        GetButton { appId: hero.app.id || ""; big: true }
    }
    MouseArea { id: ma; anchors.fill: parent; z: -1; cursorShape: Qt.PointingHandCursor; onClicked: hero.open(hero.app.id) }
}
