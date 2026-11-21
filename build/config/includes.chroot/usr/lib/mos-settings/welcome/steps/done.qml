import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../components"

Item {
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 22
        Rectangle {
            id: tick
            Layout.alignment: Qt.AlignHCenter
            width: 120; height: 120; radius: 60
            color: Theme.primary
            scale: 0
            Component.onCompleted: pop.start()
            NumberAnimation { id: pop; target: tick; property: "scale"; from: 0; to: 1; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 2 }
            Image { anchors.centerIn: parent; source: Theme.icon("check"); width: 64; height: 64; sourceSize: Qt.size(128, 128) }
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: backend.accountApi.signedIn ? "You're all set, " + backend.accountApi.name.split(" ")[0] + "!" : "You're all set!"
            color: Theme.textColour; font.pixelSize: 40; font.weight: Font.DemiBold
        }
        Hint {
            Layout.maximumWidth: 520
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: "Tip: press Win + Space (⌘ + Space on a Mac) to find anything. Settings has everything else."
        }
        PillButton {
            Layout.alignment: Qt.AlignHCenter
            text: "Start using mOS"
            implicitWidth: 220; implicitHeight: 52
            onClicked: wizard.finish()
        }
    }
}
