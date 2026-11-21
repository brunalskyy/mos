import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../components"

ColumnLayout {
    spacing: 18
    Label { text: "Connect to Wi-Fi"; color: Theme.textColour; font.pixelSize: 34; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter }
    Hint { text: "So mOS can get updates, apps and your mOS Account."; horizontalAlignment: Text.AlignHCenter }
    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.maximumWidth: 640
        Layout.alignment: Qt.AlignHCenter
        contentWidth: availableWidth
        Loader { width: parent.width; source: "../../pages/wifi.qml" }
    }
}
