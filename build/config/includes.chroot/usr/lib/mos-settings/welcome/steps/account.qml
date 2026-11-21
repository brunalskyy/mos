import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../components"

ColumnLayout {
    spacing: 18
    Label { text: "Sign in to mOS"; color: Theme.textColour; font.pixelSize: 34; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter }
    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.maximumWidth: 640
        Layout.alignment: Qt.AlignHCenter
        contentWidth: availableWidth
        Loader { width: parent.width; source: "../../pages/account.qml" }
    }
}
