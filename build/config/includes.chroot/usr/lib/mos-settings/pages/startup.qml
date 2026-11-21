import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var list: backend.startupApps()
    Connections { target: backend; function onChanged() { page.list = backend.startupApps() } }
    Hint { text: "Apps that open by themselves when you log in." }
    Card {
        pad: 10; gap: 2
        Repeater {
            model: page.list
            delegate: ListItem {
                required property var modelData
                title: modelData.name
                image: "image://icon/" + modelData.icon
                chevron: false
                MSwitch { checked: modelData.on; onToggled: function (v) { backend.setStartupApp(modelData.id, v) } }
            }
        }
        Hint { visible: page.list.length === 0; Layout.margins: 12; text: "Nothing opens at login yet." }
    }
    RowLayout { PillButton { text: "Add an app"; onClicked: { picker.apps = backend.apps(); picker.open() } } }
    Sheet {
        id: picker
        property var apps: []
        title: "Open at login"
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: 340
            clip: true
            model: picker.apps
            delegate: ListItem {
                required property var modelData
                width: ListView.view.width
                title: modelData.name; image: "image://icon/" + modelData.icon; chevron: false
                onClicked: { backend.addStartupApp(modelData.id); picker.close() }
            }
        }
    }
}
