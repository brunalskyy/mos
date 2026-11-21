import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../components"

Item {
    property int hello: 0
    readonly property var hellos: ["Hello", "Cześć", "Hola", "Bonjour", "Hallo", "Ciao", "Olá", "Привіт", "こんにちは", "Hello"]
    Timer { interval: 1600; running: true; repeat: true; onTriggered: { fadeOut.restart() } }
    SequentialAnimation {
        id: fadeOut
        NumberAnimation { target: helloText; property: "opacity"; to: 0; duration: 260 }
        ScriptAction { script: hello = (hello + 1) % hellos.length }
        NumberAnimation { target: helloText; property: "opacity"; to: 1; duration: 360 }
    }
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 26
        Image {
            id: logo
            Layout.alignment: Qt.AlignHCenter
            source: "file:///usr/share/icons/hicolor/256x256/apps/mos-logo.png"
            Layout.preferredWidth: 140; Layout.preferredHeight: 140
            sourceSize: Qt.size(280, 280)
            scale: 0.6
            Component.onCompleted: pop.start()
            SequentialAnimation {
                id: pop
                NumberAnimation { target: logo; property: "scale"; to: 1.08; duration: 420; easing.type: Easing.OutCubic }
                NumberAnimation { target: logo; property: "scale"; to: 1.0; duration: 260; easing.type: Easing.InOutQuad }
            }
        }
        Label {
            id: helloText
            Layout.alignment: Qt.AlignHCenter
            text: hellos[hello]
            color: Theme.textColour
            font.pixelSize: 64; font.weight: Font.DemiBold
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "Welcome to mOS 1.0 Amber"
            color: Theme.textVariant
            font.pixelSize: 18
        }
        PillButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            text: "Get started"
            implicitWidth: 200; implicitHeight: 52
            onClicked: win.next()
        }
    }
}
