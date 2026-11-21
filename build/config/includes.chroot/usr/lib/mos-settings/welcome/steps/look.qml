import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../components"

ColumnLayout {
    spacing: 16
    Label { text: "Make it yours"; color: Theme.textColour; font.pixelSize: 34; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter }
    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.maximumWidth: 760
        Layout.alignment: Qt.AlignHCenter
        contentWidth: availableWidth
        ColumnLayout {
            width: parent.width
            spacing: 18
            Loader { Layout.fillWidth: true; source: "../../pages/style.qml" }
            SectionTitle { text: "Icon shape" }
            Loader { Layout.fillWidth: true; source: "../../pages/icons.qml" }
        }
    }
}
