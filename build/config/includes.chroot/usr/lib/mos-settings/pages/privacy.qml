import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var apps: []
    property bool loaded: false
    Component.onCompleted: Qt.callLater(function () { page.apps = backend.privacyApps(); page.loaded = true })
    Connections { target: backend; function onJobDone(key) { if (key === "privacy") page.apps = backend.privacyApps() } }

    Hint { text: "Choose what each app from the store can use. Built-in mOS apps are already trusted." }
    Card {
        visible: page.loaded && page.apps.length === 0
        Hint { text: "No store apps yet. When you install apps from the mOS Store, they show up here." }
    }
    Repeater {
        model: page.apps
        delegate: Card {
            required property var modelData
            RowLayout {
                spacing: 14
                Image { source: "image://icon/" + modelData.icon; Layout.preferredWidth: 40; Layout.preferredHeight: 40; sourceSize: Qt.size(80, 80) }
                Label { text: modelData.name; color: Theme.onSurface; font.pixelSize: 17; font.weight: Font.DemiBold; Layout.fillWidth: true }
            }
            SettingRow { title: "Camera"; MSwitch { checked: modelData.camera; onToggled: function (v) { backend.setAppPermission(modelData.id, "camera", v) } } }
            SettingRow { title: "Microphone"; MSwitch { checked: modelData.microphone; onToggled: function (v) { backend.setAppPermission(modelData.id, "microphone", v) } } }
            SettingRow { title: "Your files"; MSwitch { checked: modelData.files; onToggled: function (v) { backend.setAppPermission(modelData.id, "files", v) } } }
        }
    }
    Card {
        ListItem { title: "Lock screen"; sub: "Password and when mOS locks"; iconName: "lockscreen"; tone: "#7C5CFF"; onClicked: Nav.top("lock") }
        ListItem { title: "Users"; sub: "Passwords and who can use this computer"; iconName: "person"; tone: "#5E35B1"; onClicked: { Nav.top("general"); Nav.go("users") } }
    }
}
