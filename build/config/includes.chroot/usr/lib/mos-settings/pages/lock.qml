import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    id: page
    spacing: 18
    property var l: backend.lockScreen()
    Connections { target: backend; function onChanged() { page.l = backend.lockScreen() } }

    Card {
        SettingRow {
            title: "Lock automatically"
            sub: "Lock mOS when you're away"
            MSwitch { checked: page.l.autolock; onToggled: function (v) { backend.setLock("Autolock", v) } }
        }
        ColumnLayout {
            visible: page.l.autolock
            Layout.fillWidth: true
            Hint { text: "Lock after" }
            Segmented {
                Layout.fillWidth: true
                options: [{ value: 1, label: "1 min" }, { value: 2, label: "2 min" }, { value: 5, label: "5 min" }, { value: 10, label: "10 min" }, { value: 30, label: "30 min" }]
                current: page.l.timeout
                onSelected: function (v) { backend.setLock("Timeout", v) }
            }
        }
        Divider {}
        SettingRow {
            title: "Lock after sleep"
            sub: "Ask for your password when the computer wakes up"
            MSwitch { checked: page.l.lockOnResume; onToggled: function (v) { backend.setLock("LockOnResume", v) } }
        }
    }
    Card {
        SettingRow {
            title: "Big clock"
            sub: "The Pixel-style stacked clock on the lock screen"
            MSwitch { checked: page.l.showClock; onToggled: function (v) { backend.setLock("alwaysShowClock", v) } }
        }
        Divider {}
        SettingRow {
            title: "Music controls"
            sub: "Play, pause and skip on the lock screen"
            MSwitch { checked: page.l.mediaControls; onToggled: function (v) { backend.setLock("showMediaControls", v) } }
        }
    }
    RowLayout {
        PillButton { text: "Lock now"; onClicked: backend.lockNow() }
        PillButton { text: "Change wallpaper"; tonal: true; onClicked: Nav.top("style") }
    }
    Hint { text: "Tip: press Win + L (⌘ + L on a Mac keyboard) to lock any time." }
}
