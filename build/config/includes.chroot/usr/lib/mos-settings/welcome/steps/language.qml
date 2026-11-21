import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../components"

ColumnLayout {
    property var l: backend.language()
    Connections { target: backend; function onChanged() { l = backend.language() } }
    spacing: 18
    Label { text: "Pick your language"; color: Theme.textColour; font.pixelSize: 34; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter }
    Hint { text: "You can change it later in Settings → General → Language & region."; horizontalAlignment: Text.AlignHCenter }
    Card {
        Layout.maximumWidth: 520
        Layout.alignment: Qt.AlignHCenter
        pad: 10; gap: 2
        Repeater {
            model: l.choices
            delegate: ListItem {
                required property var modelData
                title: modelData.label; chevron: false
                iconName: "globe"; tone: modelData.code === l.current ? Theme.primary : "#90A4AE"
                selected: modelData.code === l.current
                onClicked: backend.setLanguage(modelData.code)
            }
        }
    }
    Item { Layout.fillHeight: true }
}
