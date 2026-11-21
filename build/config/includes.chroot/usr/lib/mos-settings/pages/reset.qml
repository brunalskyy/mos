import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../components"

ColumnLayout {
    spacing: 18
    Card {
        SettingRow {
            title: "Reset look and layout"
            sub: "Puts the taskbar, desktop, widgets, wallpaper and colours back to how mOS started. Your files and apps stay."
            PillButton { text: "Reset"; tonal: true; onClicked: confirm.open() }
        }
    }
    Card {
        SettingRow {
            title: "Restart"
            sub: "Turn mOS off and on again. Save your work first."
            PillButton { text: "Restart"; outlined: true; onClicked: backend.restart() }
        }
    }
    Sheet {
        id: confirm
        title: "Reset the look and layout?"
        Hint { text: "Your taskbar, desktop and colours go back to the mOS defaults. Files, apps and accounts aren't touched." }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            PillButton { text: "Cancel"; outlined: true; onClicked: confirm.close() }
            PillButton { text: "Reset"; danger: true; onClicked: { backend.resetLook(); confirm.close() } }
        }
    }
}
