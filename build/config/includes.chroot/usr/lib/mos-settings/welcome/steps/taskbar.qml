import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../components"

ColumnLayout {
    spacing: 16
    Label { text: "Your taskbar"; color: Theme.textColour; font.pixelSize: 34; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter }
    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.maximumWidth: 760
        Layout.alignment: Qt.AlignHCenter
        contentWidth: availableWidth
        Loader { width: parent.width; source: "../../pages/taskbar.qml" }
    }
}
