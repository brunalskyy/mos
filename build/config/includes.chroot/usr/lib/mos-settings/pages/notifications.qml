import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var n: backend.notifications()
    Connections { target: backend; function onChanged() { page.n = backend.notifications() } }
    Card {
        SettingRow {
            title: "Do not disturb"
            sub: "Hide pop-ups and sounds. You'll still find everything in the notification list."
            MSwitch { checked: page.n.dnd; onToggled: function (v) { backend.setDnd(v) } }
        }
    }
    Card {
        SettingRow {
            title: "Badges on app icons"
            sub: "Show a little number on the taskbar when an app has something new"
            MSwitch { checked: page.n.badges; onToggled: function (v) { backend.setNotifyOption("InTaskManager", v) } }
        }
        Divider {}
        SettingRow {
            title: "Small pop-ups"
            sub: "Show pop-ups for less important things too"
            MSwitch { checked: page.n.lowPriority; onToggled: function (v) { backend.setNotifyOption("LowPriorityPopups", v) } }
        }
    }
}
